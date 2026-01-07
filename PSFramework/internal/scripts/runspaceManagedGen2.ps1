[PSFramework.Runspace.RunspaceHost]::ManagedRunspaceCodeGen2 = {
	param ($__PSF_Runspace)

	Set-Variable -Name __PSF_Runtime -Value $__PSF_Runspace.GetRuntime() -Option Constant
	Set-Variable -Name __PSF_Runspace -Option Constant

	$ErrorActionPreference = 'Stop'
	trap {
		if ($_.Exception.ErrorRecord) {
			$null = $__PSF_Runtime.Errors.TryAdd($_.Exception.ErrorRecord)
		}
		else {
			$null = $__PSF_Runtime.Errors.TryAdd($_)
		}
		$__PSF_Runtime.Workload.SignalFailed()
		throw
	}

	# Execute the Begin Stage
	if ($__PSF_Runtime.Begin) {
		$__PSF_Runtime.Begin.InvokeEx($true, $false, $false)
	}
	
	while ($true) {
		if ($__PSF_Runtime.Workload.State -notlike 'Running') {
			break
		}

		try {
			$null = $__PSF_Runtime.Process.InvokeEx($false, $false, $false)
		}
		catch {
			if ($_.Exception.ErrorRecord) {
				$null = $__PSF_Runtime.Errors.TryAdd($_.Exception.ErrorRecord)
			}
			else {
				$null = $__PSF_Runtime.Errors.TryAdd($_)
			}
		}

		Start-Sleep -Milliseconds 250
	}
	
	# Execute the End Stage
	if ($__PSF_Runtime.End) {
		$__PSF_Runtime.End.InvokeEx($false, $false, $false)
	}

	$__PSF_Runtime.Workload.SignalStopped()
}