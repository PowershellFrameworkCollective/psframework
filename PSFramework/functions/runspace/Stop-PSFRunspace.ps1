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
	
	.PARAMETER Runspace
		The runspace to stop. Returned by Get-PSFRunspace
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Stop-PSFRunspace -Name 'mymodule.maintenance'
		
		Stops the runspace registered under the name 'mymodule.maintenance'
	
	.NOTES
		Additional information about the function.
#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RunspaceContainer[]]
		$Runspace,
		
		[switch]
		$EnableException
	)
	
	process
	{
		foreach ($item in $Name)
		{
			# Ignore all output from Get-PSFRunspace - it'll be handled by the second loop
			if ($item -eq "psframework.runspace.runspacecontainer") { continue }
			
			if ([PSFramework.Runspace.RunspaceHost]::Runspaces.ContainsKey($item.ToLower()))
			{
				try
				{
					Write-PSFMessage -Level Verbose -Message "Stopping runspace: <c='em'>$($item.ToLower())</c>" -Target $item.ToLower() -Tag "runspace", "stop"
					[PSFramework.Runspace.RunspaceHost]::Runspaces[$item.ToLower()].Stop()
				}
				catch
				{
					Stop-PSFFunction -Message "Failed to stop runspace: <c='em'>$($item.ToLower())</c>" -EnableException $EnableException -Tag "fail", "argument", "runspace", "stop" -Target $item.ToLower() -Continue
				}
			}
			else
			{
				Stop-PSFFunction -Message "Failed to stop runspace: <c='em'>$($item.ToLower())</c> | No runspace registered under this name!" -EnableException $EnableException -Category InvalidArgument -Tag "fail", "argument", "runspace", "stop" -Target $item.ToLower() -Continue
			}
		}
		
		foreach ($item in $Runspace)
		{
			try
			{
				Write-PSFMessage -Level Verbose -Message "Stopping runspace: <c='em'>$($item.Name.ToLower())</c>" -Target $item -Tag "runspace", "stop"
				$item.Stop()
			}
			catch
			{
				Stop-PSFFunction -Message "Failed to stop runspace: <c='em'>$($item.Name.ToLower())</c>" -EnableException $EnableException -Tag "fail", "argument", "runspace", "stop" -Target $item -Continue
			}
		}
	}
}