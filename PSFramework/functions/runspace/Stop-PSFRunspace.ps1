function Stop-PSFRunspace
{
<#
	.SYNOPSIS
		Stops a runspace that was registered to the PSFramework
	
	.DESCRIPTION
		Stops a runspace that was registered to the PSFramework
		Will not cause errors if the runspace is already halted.
	
		Runspaces may not automatically terminate immediately when calling this function.
		Depending on the implementation of the scriptblock, this may in fact take a little time.
		If the scriptblock hasn't finished and terminated the runspace in a seemingly time, it will be killed by the system.
		This timeout is by default 30 seconds, but can be altered by using the Configuration System.
		For example, this line will increase the timeout to 60 seconds:
		Set-PSFConfig -FullName PSFramework.Runspace.StopTimeout -Value 60
	
	.PARAMETER Name
		The name of the registered runspace to stop
	
	.EXAMPLE
		PS C:\> Stop-PSFRunspace -Name 'mymodule.maintenance'
	
		Stops the runspace registered under the name 'mymodule.maintenance'
#>
	[CmdletBinding()]
	Param (
		[string]
		$Name
	)
	
	if ([PSFramework.Runspace.RunspaceHost]::Runspaces.ContainsKey($Name.ToLower()))
	{
		Write-PSFMessage -Level Verbose -Message "Stopping runspace: <c='Green'>$($Name.ToLower())</c>" -Target $Name.ToLower()
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$Name.ToLower()].Stop()
	}
	else
	{
		Write-PSFMessage -Level Warning -Message "Failed to stop runspace: <c='Green'>$($Name.ToLower())</c> | No runspace registered under this name!" -Target $Name.ToLower()
	}
}