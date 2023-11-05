function Write-PSFRunspaceQueue {
	<#
	.SYNOPSIS
		Write data to a queue of a Runspace Workflow Dispatcher.
	
	.DESCRIPTION
		Write data to a queue of a Runspace Workflow Dispatcher.
		This is generally used to provide the initial input of the first queue.

		Can also be used by a worker code to provide output to more than one queue.
	
	.PARAMETER Name
		Name of the Queue to write to.
	
	.PARAMETER Value
		The value to write.

	.PARAMETER BulkValues
		Write multiple values as separate entries.

	.PARAMETER Close
		Closes the queue after writing the input.
		This prevents further data to be added to the queue,
		and allows a worker to know, when it has fully processed input.

	.PARAMETER DispatcherName
		Name of the dispatcher owning the queue written to.
	
	.PARAMETER InputObject
		Dispatcher object that owns the queue written to.
	
	.EXAMPLE
		PS C:\> $dispatcher | Write-PSFRunspaceQueue -Name input -BulkValues $entries

		Provides all values in $entries as input for the queue named "input"
		of the Runspace Workflow Dispatcher in $dispatcher.
	
	.LINK
		TODO: Add link to section
	#>
	[CmdletBinding(DefaultParameterSetName = 'Single')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ParameterSetName = 'Single')]
		[AllowNull()]
		$Value,

		[Parameter(Mandatory = $true, ParameterSetName = 'Multi')]
		[AllowNull()]
		[object[]]
		$BulkValues,

		[switch]
		$Close,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$DispatcherName,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject
	)
	process {
		$resolvedDispatchers = Resolve-PsfRunspaceDispatcher -Name $DispatcherName -InputObject $InputObject -Cmdlet $PSCmdlet -Terminate -CurrentWorker
		foreach ($resolvedDispatcher in $resolvedDispatchers) {
			$values = $BulkValues
			if ($PSBoundParameters.Keys -contains 'Value') {
				$values = $Value
			}
			foreach ($item in $values) {
				$resolvedDispatcher.Queues.$Name.Enqueue($item)
				if ($global:__PSF_Worker -and $Name -eq $global:__PSF_Worker.OutQueue) {
					$global:__PSF_Worker.IncrementOutput()
				}
			}
			if ($Close) { $resolvedDispatcher.CloseQueue($Name) }
		}
	}
}