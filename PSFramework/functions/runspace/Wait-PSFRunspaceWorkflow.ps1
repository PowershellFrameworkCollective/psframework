function Wait-PSFRunspaceWorkflow {
	<#
	.SYNOPSIS
		Wait for a Runspace Workflow to complete.

	.DESCRIPTION
		Wait for a Runspace Workflow to complete.

	.PARAMETER Queue
		The name of the queue to measure completion by.
		Usually the last output queue in the chain of steps.

	.PARAMETER WorkerName
		The name of the worker to measure completion by.
		Usually the last step in the chain of steps.

	.PARAMETER Closed
		The workflow is considered completed, when the queue or worker selected is closed.

	.PARAMETER Count
		The workflow is considered completed, when the queue selected has received the specified number of results.
		This looks at the total amount ever provided, not current number queued.

	.PARAMETER ReferenceQueue
		The workflow is considered completed, when the queue selected has received the same number of items as the reference queue.

	.PARAMETER ReferenceMultiplier
		When comparing the result queue with a reference queue, multiply the number of items in the reference queue by this value.
		Use when the number of output items, based from the original input, scales by a constant multiplier.
		Defaults to 1.

	.PARAMETER QueueTimeout
		Wait based on how long ago the last item was added to the specified queue.

	.PARAMETER PassThru
		Pass through the workflow object waiting for.
		Useful to stop it once waiting has completed.

	.PARAMETER Timeout
		Maximum wait time. Throws an error if exceeded.
		Defaults to 1 day.

	.PARAMETER Name
		Name of the workflow to wait for.

	.PARAMETER InputObject
		A runspace workflow object to wait for.

	.PARAMETER ShowProgress
        To show a progressbar while waiting for runspace completion

	.EXAMPLE
		PS C:\> $workflow | Wait-PSFRunspaceWorkflow -Queue Done -Count 1000

		Wait until 1000 items have been queued to "Done" in total.

	.EXAMPLE
		PS C:\> $workflow | Wait-PSFRunspaceWorkflow -Queue Done -PassThru | Stop-PSFRunspaceWorkflow

		Wait until the "Done" queue has been closed, then stop the workflow.

	.EXAMPLE
		PS C:\> $workflow | Wait-PSFRunspaceWorkflow -Queue Done -ReferenceQueue Input

		Wait until the "Done" queue has processed as many items as there were written to the "Input" queue.

	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'Closed')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'QueueTimeout')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Closed')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Count')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Reference')]
		[string]
		$Queue,

		[Parameter(Mandatory = $true, ParameterSetName = 'WorkerClosed')]
		[Parameter(Mandatory = $true, ParameterSetName = 'WorkerCount')]
		[Parameter(Mandatory = $true, ParameterSetName = 'WorkerReference')]
		[string]
		$WorkerName,

		[Parameter(ParameterSetName = 'Closed')]
		[Parameter(Mandatory = $true, ParameterSetName = 'WorkerClosed')]
		[switch]
		$Closed,

		[Parameter(Mandatory = $true, ParameterSetName = 'WorkerCount')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Count')]
		[int]
		$Count,

		[Parameter(Mandatory = $true, ParameterSetName = 'WorkerReference')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Reference')]
		[string]
		$ReferenceQueue,

		[Parameter(ParameterSetName = 'WorkerReference')]
		[Parameter(ParameterSetName = 'Reference')]
		[int]
		$ReferenceMultiplier = 1,

		[Parameter(Mandatory = $true, ParameterSetName = 'QueueTimeout')]
		[PSFramework.Parameter.TimeSpanParameter]
		$QueueTimeout,

		[switch]
		$PassThru,

		[switch]
		$ShowProgress,

		[PSFramework.Parameter.TimeSpanParameter]
		$Timeout,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('PSFramework-runspace-workflow-name')]
		[string[]]
		$Name,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSWorkflow[]]
		$InputObject
	)
	begin {
		#region Utility Functions
		function Write-WorkflowProgress {
			[CmdletBinding()]
			param (
				[string]
				$Mode,

				[DateTime]
				$Start,

				$Workflow,

				[int]
				$CurrentCount,

				[string]
				$QueueName,

				$QueueObject,

				[string]
				$WorkerName,

				[int]
				$WorkflowProgressID,

				[hashtable]
				$WorkerIDs,

				[int]
				$TargetCount
			)

			$elapsed = ([int]((Get-Date) - $Start).TotalSeconds)
			$overallCurrent = 0
			if ($QueueName) { $overallCurrent = $Workflow.Queues.$QueueName.TotalItemCount }
			if ($WorkerName) { $overallCurrent = $Workflow.Workers.$WorkerName.CountInputCompleted }
			if ($QueueObject) { $overallCurrent = $QueueObject.TotalItemCount }
			if ($PSBoundParameters.Keys -contains 'CurrentCount') { $overallCurrent = $CurrentCount }

			$targetString = ''
			if ($TargetCount) { $targetString = "/$TargetCount" }

			Write-Progress -Id $WorkflowProgressID -Activity "Workflow: $($Workflow.Name)" -Status "Mode:$Mode | Current:$overallCurrent$($targetString) | Elapsed:$($elapsed)s" -PercentComplete -1

			foreach ($workerObjName in $Workflow.Workers.Keys) {
				$workerObj = $Workflow.Workers.$workerObjName

				$inQueueName = if ($workerObj.PSObject.Properties.Name -contains 'InQueue') { $workerObj.InQueue } else { $null }
				$outQueueName = $workerObj.OutQueue

				$inQeue = $null
				if ($inQueueName) { $inQeue = $Workflow.Queues.($inQueueName) }
				$outQueue = $null
				if ($outQueueName) { $outQueue = $Workflow.Queues.($outQueueName) }

				$inTotal = if ($inQeue) { $inQeue.TotalItemCount } else { 0 }
				$outTotal = if ($outQueue) { $outQueue.TotalItemCount } else { 0 }
				$outClosed = if ($outQueue) { $outQueue.Closed } else { $false }
				$current = $workerObj.CountInputCompleted

				Write-Progress -Id $WorkerIDs[$workerObjName].RunnerId -ParentId $WorkflowProgressID -Activity "Runner: $workerObjName" -Status "Progress: $current$($targetString) | Elapsed:$($elapsed)s" -PercentComplete -1

				# Items status (only print non-empty fields)
				$parts = @("Completed:$current")
				if ($inQueueName) { $parts += "InQ:$inQueueName total:$inTotal" }
				if ($outQueueName) { $parts += "OutQ:$outQueueName total:$outTotal closed:$outClosed" }
				$itemStatus = ($parts -join ' | ')
				Write-Progress -Id $WorkerIDs[$workerObjName].ItemsId -ParentId $WorkerIDs[$workerObjName].RunnerId -Activity "# of items" -Status $itemStatus -PercentComplete -1
			}
		}
		#endregion Utility Functions
	}
	process {
		$resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $Name -InputObject $InputObject -Cmdlet $PSCmdlet
		$limit = (Get-Date).AddDays(1)
		if ($Timeout) { $limit = (Get-Date).Add($Timeout) }

		# base progress id counter (simple, monotonic)
		$progressId = 1

		foreach ($resolvedWorkflow in $resolvedWorkflows) {
			$start = Get-Date

			if ($ShowProgress) {
				$workflowProgressID = $progressId
				$progressId += 1
				Write-Progress -Id $workflowProgressID -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Elapsed: 0s" -PercentComplete -1

				$workerIds = @{}
				foreach ($workerObjName in $resolvedWorkflow.Workers.Keys) {
					$runnerId = $progressId
					$itemsId = $progressId + 1
					$progressId += 2
					$workerIds[$workerObjName] = @{
						RunnerId = $runnerId
						ItemsId = $itemsId
					}
					Write-Progress -Id $runnerId -ParentId $workflowProgressID -Activity "Runner: $workerObjName" -Status "Initializing..." -PercentComplete -1
					Write-Progress -Id $itemsId -ParentId $runnerId -Activity "Nb of items" -Status "Initializing..." -PercentComplete -1
				}
			}

			switch ($PSCmdlet.ParameterSetName) {
				'Closed' {
					while (-not $resolvedWorkflow.Queues.$Queue.Closed) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						if ($ShowProgress) {
							Write-WorkflowProgress -Mode $PSCmdlet.ParameterSetName -Start $start -Workflow $resolvedWorkflow -QueueName $Queue -WorkflowProgressID $workflowProgressID -WorkerIDs $workerIds
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'WorkerClosed' {
					$queueObject = $resolvedWorkflow.Queues[$resolvedWorkflow.Workers.$WorkerName.OutQueue]
					while (-not $queueObject.Closed) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						if ($ShowProgress) {
							Write-WorkflowProgress -Mode $PSCmdlet.ParameterSetName -Start $start -Workflow $resolvedWorkflow -QueueObject $queueObject -WorkflowProgressID $workflowProgressID -WorkerIDs $workerIds
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'Count' {
					while ($resolvedWorkflow.Queues.$Queue.TotalItemCount -lt $Count) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						if ($ShowProgress) {
							Write-WorkflowProgress -Mode $PSCmdlet.ParameterSetName -Start $start -Workflow $resolvedWorkflow -QueueName $Queue -WorkflowProgressID $workflowProgressID -WorkerIDs $workerIds -TargetCount $Count
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'WorkerCount' {
					while ($resolvedWorkflow.Workers.$WorkerName.CountInputCompleted -lt $Count) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						if ($ShowProgress) {
							Write-WorkflowProgress -Mode $PSCmdlet.ParameterSetName -Start $start -Workflow $resolvedWorkflow -WorkerName $WorkerName -WorkflowProgressID $workflowProgressID -WorkerIDs $workerIds -TargetCount $Count
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'Reference' {
					while ($resolvedWorkflow.Queues.$Queue.TotalItemCount -lt ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						if ($ShowProgress) {
							Write-WorkflowProgress -Mode $PSCmdlet.ParameterSetName -Start $start -Workflow $resolvedWorkflow -QueueName $Queue -WorkflowProgressID $workflowProgressID -WorkerIDs $workerIds -TargetCount ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'WorkerReference' {
					while ($resolvedWorkflow.Workers.$WorkerName.CountInputCompleted -lt ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						if ($ShowProgress) {
							Write-WorkflowProgress -Mode $PSCmdlet.ParameterSetName -Start $start -Workflow $resolvedWorkflow -WorkerName $WorkerName -WorkflowProgressID $workflowProgressID -WorkerIDs $workerIds -TargetCount ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'QueueTimeout' {
					while ($resolvedWorkflow.Queues.$Queue.LastUpdate -gt (Get-Date).AddTicks(-1 * $QueueTimeout.Value.Ticks)) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						if ($ShowProgress) {
							$sinceLast = (Get-Date) - $resolvedWorkflow.Queues.$Queue.LastUpdate
							Write-WorkflowProgress -Mode $PSCmdlet.ParameterSetName -Start $start -Workflow $resolvedWorkflow -CurrentCount $sinceLast.TotalSeconds -WorkflowProgressID $workflowProgressID -WorkerIDs $workerIds -TargetCount $QueueTimeout.Value.TotalSeconds
						}
						Start-Sleep -Milliseconds 200
					}
				}
			}

			if ($ShowProgress) {
				foreach ($workerObjName in $workerIds.Keys) {
					Write-Progress -Id $workerIds[$workerObjName].ItemsId -Activity "# of items" -Completed
					Write-Progress -Id $workerIds[$workerObjName].RunnerId -Activity "Runner" -Completed
				}
				Write-Progress -Id $WorkflowProgressID -Activity "Workflow" -Completed
			}

			if ($PassThru) { $resolvedWorkflow }
		}
	}
}
