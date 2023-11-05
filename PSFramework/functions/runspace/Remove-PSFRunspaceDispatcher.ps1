function Remove-PSFRunspaceDispatcher {
	<#
	.SYNOPSIS
		Removes a Runspace Workflow Dispatcher, stopping all processing.
	
	.DESCRIPTION
		Removes a Runspace Workflow Dispatcher, stopping all processing.
		This stops all workers, ends all runspaces and unlists the dispatcher object.

		The queues remain untouched, but will be garbage collected together with the dispatcher object,
		assuming no variable outside of the module retains it.
	
	.PARAMETER Name
		The name of the Runspace Workflow Dispatcher to remove.
	
	.EXAMPLE
		PS C:\> Get-PSFRunspaceDispatcher | Remove-PSFRunspaceDispatcher

		Stops and removes all runspace dispatchers.
	
	.LINK
		TODO: Add link to section

	.LINK
		Get-PSFRunspaceDispatcher

	.LINK
		New-PSFRunspaceDispatcher
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	process {
		foreach ($entry in $Name) {
			if (-not $script:runspaceDispatchers[$entry]) { continue }
			$script:runspaceDispatchers[$entry].Stop()
			$script:runspaceDispatchers.Remove($entry)
		}
	}
}