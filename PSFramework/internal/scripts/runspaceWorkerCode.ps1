﻿[PSFramework.Runspace.RSWorker]::WorkerCode = {
	param (
		$__PSF_WorkerID
	)
	# $__PSF_Workflow --> Workload Workflow provided by worker
	# $__PSF_Worker --> Current Worker Definition

	$ErrorActionPreference = 'Stop'
	trap {
		Write-PSFMessage -Level Error -Message "Runspace Worker Code failed" -ErrorRecord $_
		$__PSF_Worker.State = 'Failed'
		$__PSF_Worker.SignalEnd()
		throw $_
	}

	try {
		[runspace]::DefaultRunspace.Name = 'PSF-{0}-{1}-{2}' -f $__PSF_Workflow.Name, $__PSF_Worker.Name, $__PSF_WorkerID
	}
	catch {
		# No action - name is desirable, but cosmetic
	}

	# Generally, Constants are to be avoided. To guarantee no childcode can override the code to be executed, this is made constant.
	Set-Variable -Name __PSF_Begin -Value $__PSF_Worker.GetBegin() -Option Constant
	Set-Variable -Name __PSF_ScriptBlock -Value $__PSF_Worker.ScriptBlock -Option Constant
	Set-Variable -Name __PSF_End -Value $__PSF_Worker.GetEnd() -Option Constant

	# Consume per-Runspace Values as variables
	foreach ($key in $__PSF_Worker.PerRSValues.Keys) {
		Set-Variable -Name $key -Value $__PSF_Worker.PerRSValues[$key].Dequeue()
	}
	
	if ($__PSF_Begin) {
		try { $null = & $__PSF_Begin }
		catch {
			$__PSF_Worker.ErrorCount++
			$__PSF_Worker.LastError = $_

			# End worker right away to ensure the error is not drowned in subsequent errors
			return
		}
	}

	$validStates = 'Starting', 'Running'
	while ($validStates -contains $__PSF_Worker.State) {
		# Inqueue is closed and all items processed?
		if ($__PSF_Worker.IsDone) { break }
		if ($__PSF_Worker.MaxItems -and $__PSF_Worker.MaxItems -le $__PSF_Worker.CountInputCompleted) { break }

		if ($__PSF_Worker.Throttle) {
			$__PSF_Worker.Throttle.GetSlot()
		}

		$inputData = $null
		$success = $__PSF_Worker.GetNext([ref]$inputData)
		if (-not $success) {
			Start-Sleep -Milliseconds 250
			continue
		}

		try {
			$results = $__PSF_ScriptBlock.InvokeGlobal($inputData)
			foreach ($result in $results) {
				$__PSF_Workflow.Queues.$($__PSF_Worker.OutQueue).Enqueue($result)
				$__PSF_Worker.IncrementOutput()
			}
			$__PSF_Worker.IncrementInputCompleted()
		}
		catch {
			$__PSF_Worker.IncrementInputCompleted()
			$__PSF_Worker.ErrorCount++
			$__PSF_Worker.AddError($_, $inputData)
		}
	}

	if ($__PSF_End) {
		try { $null = & $__PSF_End }
		catch {
			$__PSF_Worker.ErrorCount++
			$__PSF_Worker.LastError = $_
		}
	}

	$__PSF_Worker.SignalEnd()
}