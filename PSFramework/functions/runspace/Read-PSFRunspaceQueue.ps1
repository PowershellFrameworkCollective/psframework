function Read-PSFRunspaceQueue {
	<#
	.SYNOPSIS
		Reads data from a queue associated with a runspace workflow dispatcher.
	
	.DESCRIPTION
		Reads data from a queue associated with a runspace workflow dispatcher.
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
	
	.PARAMETER DispatcherName
		Name of the Runspace Dispatcher the queue read from belongs to.
		The dispatcher contains all the workers, queues and management tools for the Runspace Workload.
	
	.PARAMETER InputObject
		Dispatcher object of the Runspace Dispatcher the queue read from belongs to.
		The dispatcher contains all the workers, queues and management tools for the Runspace Workload.
	
	.EXAMPLE
		PS C:\> $dispatcher | Read-PSFRunspaceQueue -Name Done -All

		Read / retrieve all items from the queue "Done" of the dispatcher $dispatcher

	.EXAMPLE
		PS C:\> Read-PSFRunspaceQueue -Name extraData

		Read a value from "extraData" queue of the current Runspace Workflow Dispatcher.
		Only works from within the code of a running worker.
		Keep in mind that worker code automatically receives input from the specified input queue.
	
	.LINK
		TODO: Add link to section
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
		[string[]]
		$DispatcherName,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject
	)
	process {
		$resolvedDispatchers = Resolve-PsfRunspaceDispatcher -Name $DispatcherName -InputObject $InputObject -Cmdlet $PSCmdlet -Terminate -CurrentWorker
		if ($Continual -and $resolvedDispatchers.Count -gt 1) {
			Stop-PSFFunction -String 'Read-PSFRunspaceQueue.Error.Continual.TooManyDispatchers' -StringValues $Name, ($resolvedDispatchers.Name -join ', ') -EnableException $true -Category InvalidOperation -Cmdlet $PSCmdlet
		}

		#region Continual Streaming Mode
		if ($Continual) {
			$queue = $resolvedDispatcher.Queues.$Name
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

		foreach ($resolvedDispatcher in $resolvedDispatchers) {
			if ($All) {
				$resolvedDispatcher.Queues.$Name.ToArray()
				$resolvedDispatcher.Queues.$Name.Clear()
				continue
			}
			$result = $resolvedDispatcher.Queues.$Name.Dequeue()
			if ($null -ne $result) { $result }
		}
	}
}