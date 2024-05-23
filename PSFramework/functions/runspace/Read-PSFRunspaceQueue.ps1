function Read-PSFRunspaceQueue {
	<#
	.SYNOPSIS
		Reads data from a queue associated with a runspace workflow.
	
	.DESCRIPTION
		Reads data from a queue associated with a runspace workflow.
		Can be used to receive the final workflow results or to collect data outside of the default workflow.
		Note: Reading data from a queue removes the item from it!
	
	.PARAMETER Name
		Name of the queue to read data from.
	
	.PARAMETER All
		Retrieve all items from the queue.
		By default, only the oldest entry is returned.

	.PARAMETER Continual
		Keep reading data from the queue until the queue is closed and emptied.
		Intended for use in situations, where a processing worker must run within a single pipeline,
		rather than the default, repeated calls of the processing scriptblock per queue item.
	
	.PARAMETER WorkflowName
		Name of the Runspace Workflow the queue read from belongs to.
		The workflow contains all the workers, queues and management tools for the Runspace Workload.
	
	.PARAMETER InputObject
		Workflow object the queue read from belongs to.
		The workflow contains all the workers, queues and management tools for the Runspace Workload.
	
	.EXAMPLE
		PS C:\> $workflow | Read-PSFRunspaceQueue -Name Done -All

		Read / retrieve all items from the queue "Done" of the workflow $workflow

	.EXAMPLE
		PS C:\> Read-PSFRunspaceQueue -Name extraData

		Read a value from "extraData" queue of the current Runspace Workflow.
		Only works from within the code of a running worker.
		Keep in mind that worker code automatically receives input from the specified input queue.
	
	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[switch]
		$All,

		[switch]
		$Continual,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('PSFramework-runspace-workflow-name')]
		[string[]]
		$WorkflowName,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSWorkflow[]]
		$InputObject
	)
	process {
		$resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $WorkflowName -InputObject $InputObject -Cmdlet $PSCmdlet -Terminate -CurrentWorker
		if ($Continual -and $resolvedWorkflows.Count -gt 1) {
			Stop-PSFFunction -String 'Read-PSFRunspaceQueue.Error.Continual.TooManyWorkflows' -StringValues $Name, ($resolvedWorkflows.Name -join ', ') -EnableException $true -Category InvalidOperation -Cmdlet $PSCmdlet
		}

		#region Continual Streaming Mode
		if ($Continual) {
			$queue = $resolvedWorkflow.Queues.$Name
			while ($queue.Count -gt 1 -and -not $queue.Closed) {
				$result = $null
				$success = $queue.TryDequeue([ref]$result)
				if (-not $success) {
					Start-Sleep -Milliseconds 250
					continue
				}
				if ($null -ne $result) { $result }
			}
			return
		}
		#endregion Continual Streaming Mode

		foreach ($resolvedWorkflow in $resolvedWorkflows) {
			if ($All) {
				# Cache Results so downstream pipeline commands do not interfere with the clearing
				$results = $resolvedWorkflow.Queues.$Name.ToArray()
				$resolvedWorkflow.Queues.$Name.Clear()
				$results
				continue
			}
			$result = $resolvedWorkflow.Queues.$Name.Dequeue()
			if ($null -ne $result) { $result }
		}
	}
}