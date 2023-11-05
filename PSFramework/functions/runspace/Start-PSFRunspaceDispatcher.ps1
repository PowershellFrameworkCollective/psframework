function Start-PSFRunspaceDispatcher {
	<#
	.SYNOPSIS
		Starts a Runspace Workflow Dispatcher.
	
	.DESCRIPTION
		Starts a Runspace Workflow Dispatcher.
		This will launch all workers and their associated runspaces.

		Consider queuing input first (Write-PSFRunspaceQueue) before starting the workflow.
	
	.PARAMETER Name
		Name of the Runspace Workflow Dispatcher to launch.
	
	.PARAMETER InputObject
		Runspace Workflow Dispatcher object to launch.
	
	.EXAMPLE
		PS C:\> Start-PSRunspaceDispatcher -Name MailboxAnalysis

		Starts the Runspace Workflow Dispatcher "MailboxAnalysis"

	.EXAMPLE
		PS C:\> Get-PSFRunspaceDispatcher | Start-PSFRunspaceDispatcher

		Start all Runspace Worklflow Dispatchers.
	
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
			$resolvedDispatcher.Start()
		}
	}
}