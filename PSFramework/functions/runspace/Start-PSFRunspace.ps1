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
	
	.PARAMETER NoMessage
		Setting this will prevent messages be written to the message / logging system.
		This is designed to make the PSFramework not flood the log on each import.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Start-PSFRunspace -Name 'mymodule.maintenance'
		
		Starts the runspace registered under the name 'mymodule.maintenance'
#>
	[CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Start-PSFRunspace')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RunspaceContainer[]]
		$Runspace,
		
		[switch]
		$NoMessage,
		
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
				if ($PSCmdlet.ShouldProcess($item, "Starting Runspace"))
				{
					try
					{
						if (-not $NoMessage) { Write-PSFMessage -Level Verbose -Message "Starting runspace: <c='em'>$($item.ToLower())</c>" -Target $item.ToLower() -Tag "runspace", "start" }
						[PSFramework.Runspace.RunspaceHost]::Runspaces[$item.ToLower()].Start()
					}
					catch
					{
						Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.ToLower())</c>" -ErrorRecord $_ -EnableException $EnableException -Tag "fail", "argument", "runspace", "start" -Target $item.ToLower() -Continue
					}
				}
			}
			else
			{
				Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.ToLower())</c> | No runspace registered under this name!" -EnableException $EnableException -Category InvalidArgument -Tag "fail", "argument", "runspace", "start" -Target $item.ToLower() -Continue
			}
		}
		
		foreach ($item in $Runspace)
		{
			if ($PSCmdlet.ShouldProcess($item.Name, "Starting Runspace"))
			{
				try
				{
					if (-not $NoMessage) { Write-PSFMessage -Level Verbose -Message "Starting runspace: <c='em'>$($item.Name.ToLower())</c>" -Target $item -Tag "runspace", "start" }
					$item.Start()
				}
				catch
				{
					Stop-PSFFunction -Message "Failed to start runspace: <c='em'>$($item.Name.ToLower())</c>" -EnableException $EnableException -Tag "fail", "argument", "runspace", "start" -Target $item -Continue
				}
			}
		}
	}
}