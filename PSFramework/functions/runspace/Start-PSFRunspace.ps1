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
	
	.PARAMETER Runspace
		The runspace to launch. Returned by Get-PSFRunspace
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Start-PSFRunspace -Name 'mymodule.maintenance'
		
		Starts the runspace registered under the name 'mymodule.maintenance'
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
					Write-PSFMessage -Level Verbose -Message "Starting runspace: <c='em'>$($item.ToLower())</c>" -Target $item.ToLower() -Tag "runspace", "start"
					[PSFramework.Runspace.RunspaceHost]::Runspaces[$item.ToLower()].Start()
				}
				catch
				{
					Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.ToLower())</c>" -EnableException $EnableException -Tag "fail", "argument", "runspace", "start" -Target $item.ToLower() -Continue
				}
			}
			else
			{
				Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.ToLower())</c> | No runspace registered under this name!" -EnableException $EnableException -Category InvalidArgument -Tag "fail", "argument", "runspace", "start" -Target $item.ToLower() -Continue
			}
		}
		
		foreach ($item in $Runspace)
		{
			try
			{
				Write-PSFMessage -Level Verbose -Message "Starting runspace: <c='em'>$($item.Name.ToLower())</c>" -Target $item -Tag "runspace","start"
				$item.Start()
			}
			catch
			{
				Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.Name.ToLower())</c>" -EnableException $EnableException -Tag "fail", "argument", "runspace", "start" -Target $item -Continue
			}
		}
	}
}