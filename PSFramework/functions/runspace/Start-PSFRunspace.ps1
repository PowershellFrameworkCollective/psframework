function Start-PSFRunspace
{
<#
	.SYNOPSIS
		Starts a runspace that was registered to the PSFramework
	
	.DESCRIPTION
		Starts a runspace that was registered to the PSFramework
		Simply registering does not automatically start a given runspace. Only by executing this function will it take effect.
	
	.PARAMETER Name
		The name of the registered runspace to launch
	
	.EXAMPLE
		PS C:\> Start-PSFRunspace -Name 'mymodule.maintenance'
	
		Starts the runspace registered under the name 'mymodule.maintenance'
#>
	[CmdletBinding()]
	Param (
		[string]
		$Name
	)
	
	if ([PSFramework.Runspace.RunspaceHost]::Runspaces.ContainsKey($Name.ToLower()))
	{
		Write-PSFMessage -Level Verbose -Message "Starting runspace: <c='Green'>$($Name.ToLower())</c>" -Target $Name.ToLower()
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$Name.ToLower()].Start()
	}
	else
	{
		Write-PSFMessage -Level Warning -Message "Failed to start runspace: <c='Green'>$($Name.ToLower())</c> | No runspace registered under this name!" -Target $Name.ToLower()
	}
}