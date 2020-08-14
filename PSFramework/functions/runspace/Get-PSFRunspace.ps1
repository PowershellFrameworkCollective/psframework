function Get-PSFRunspace
{
<#
	.SYNOPSIS
		Returns registered runspaces.
	
	.DESCRIPTION
		Returns a list of runspaces that have been registered with the PSFramework
	
	.PARAMETER Name
		Default: "*"
		Only registered runspaces of similar names are returned.
	
	.EXAMPLE
		PS C:\> Get-PSFRunspace
	
		Returns all registered runspaces
	
	.EXAMPLE
		PS C:\> Get-PSFRunspace -Name 'mymodule.maintenance'
	
		Returns the runspace registered under the name 'mymodule.maintenance'
#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFRunspace')]
	Param (
		[string]
		$Name = "*"
	)
	
	process
	{
		[PSFramework.Runspace.RunspaceHost]::Runspaces.Values | Where-Object Name -Like $Name
	}
}