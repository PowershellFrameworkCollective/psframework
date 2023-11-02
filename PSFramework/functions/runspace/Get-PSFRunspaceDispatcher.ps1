function Get-PSFRunspaceDispatcher {
	<#
	.SYNOPSIS
		Returns a list of registered runspace dispatchers.
	
	.DESCRIPTION
		Returns a list of registered runspace dispatchers.
		A Runspace dispatcher is the main component managing a PSFramework Runspace Workflow
	
	.PARAMETER Name
		By which name to filter.
		Defaults to *
	
	.EXAMPLE
		PS C:\> Get-PSFRunspaceDispatcher
		
		Returns all registered runspace dispatchers.

	.LINK
		TODO: Add link to section
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name = '*'
	)
	process {
		($script:runspaceDispatchers.Values | Where-Object Name -Like $Name)
	}
}