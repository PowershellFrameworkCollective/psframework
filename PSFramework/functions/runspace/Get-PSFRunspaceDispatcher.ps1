function Get-PSFRunspaceDispatcher {
	[CmdletBinding()]
	param (
		[string]
		$Name = '*'
	)
	process {
		$script:runspaceDispatchers.Values | Where-Object Name -Like $Name
	}
}