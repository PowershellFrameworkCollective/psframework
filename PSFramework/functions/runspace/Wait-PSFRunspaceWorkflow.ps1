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
	process {
		$resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $Name -InputObject $InputObject -Cmdlet $PSCmdlet
		$limit = (Get-Date).AddDays(1)
		if ($Timeout) { $limit = (Get-Date).Add($Timeout) }

		foreach ($resolvedWorkflow in $resolvedWorkflows) {
			switch ($PSCmdlet.ParameterSetName) {
				'Closed' {
					while (-not $resolvedWorkflow.Queues.$Queue.Closed) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
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
						Start-Sleep -Milliseconds 200
					}
				}
				'Count' {
					while ($resolvedWorkflow.Queues.$Queue.TotalItemCount -lt $Count) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'WorkerCount' {
					while ($resolvedWorkflow.Workers.$WorkerName.CountInputCompleted -lt $Count) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'Reference' {
					while ($resolvedWorkflow.Queues.$Queue.TotalItemCount -lt ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'WorkerReference' {
					while ($resolvedWorkflow.Workers.$WorkerName.CountInputCompleted -lt ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						Start-Sleep -Milliseconds 200
					}
				}
				'QueueTimeout' {
					while ($resolvedWorkflow.Queues.$Queue.LastUpdate -gt (Get-Date).AddTicks(-1 * $QueueTimeout.Value.Ticks)) {
						if ($limit -lt (Get-Date)) {
							Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
						}
						Start-Sleep -Milliseconds 200
					}
				}
			}

			if ($PassThru) { $resolvedWorkflow }
		}
	}
}