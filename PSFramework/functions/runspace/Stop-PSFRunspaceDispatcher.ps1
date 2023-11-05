function Stop-PSFRunspaceDispatcher {
	<#
	.SYNOPSIS
		Stop a running Runspace Workflow Dispatcher.
	
	.DESCRIPTION
		Stop a running Runspace Workflow Dispatcher.
		This shuts down all running runspaces of all associated workers.
		Queues will remain unaffected, and the Dispatcher remains registered and available.

		To fully remove it, use Remove-PSFRunspaceDispatcher instead.
	
	.PARAMETER Name
		The name of the Runspace Workflow Dispatcher to stop.
	
	.PARAMETER InputObject
		The Runspace Workflow Dispatcher object to stop.
	
	.EXAMPLE
		PS C:\> $dispatcher | Stop-PSFRunspaceDispatcher

		Stops the specified Runspace Workflow Dispatcher.
	
	.LINK
		TODO: Add link to section
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject
	)
	process {
		$resolvedDispatchers = Resolve-PsfRunspaceDispatcher -Name $Name -InputObject $InputObject -Cmdlet $PSCmdlet

		foreach ($resolvedDispatcher in $resolvedDispatchers) {
			$resolvedDispatcher.Stop()
		}
	}
}