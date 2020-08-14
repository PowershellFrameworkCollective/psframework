function Register-PSFRunspace
{
<#
	.SYNOPSIS
		Registers a scriptblock to run in the background.
	
	.DESCRIPTION
		This function registers a scriptblock to run in separate runspace.
		This is different from most runspace solutions, in that it is designed for permanent background tasks that need to be done.
		It guarantees a single copy of the task to run within the powershell process, even when running the same module in many runspaces in parallel.
		
		The scriptblock must be built with some rules in mind, for details on using this system run:
		Get-Help about_psf_runspace
	
		Updating:
		If this function is called multiple times, targeting the same name, it will update the scriptblock.
		- If that scriptblock is the same as the previous scriptblock, nothing changes
		- If that scriptblock is different from the previous ones, it will be registered, but will not be executed right away!
		  Only after stopping and starting the runspace will it operate under the new scriptblock.
	
	.PARAMETER ScriptBlock
		The scriptblock to run in a dedicated runspace.
	
	.PARAMETER Name
		The name to register the scriptblock under.
	
	.PARAMETER NoMessage
		Setting this will prevent messages be written to the message / logging system.
		This is designed to make the PSFramework not flood the log on each import.
	
	.EXAMPLE
		PS C:\> Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'mymodule.maintenance'
	
		Registers the script defined in $scriptBlock under the name 'mymodule.maintenance'
		It does not start the runspace yet. If it already exists, it will overwrite the scriptblock without affecting the running script.
	
	.EXAMPLE
		PS C:\> Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'mymodule.maintenance'
		PS C:\> Start-PSFRunspace -Name 'mymodule.maintenance'
	
		Registers the script defined in $scriptBlock under the name 'mymodule.maintenance'
		Then it starts the runspace, running the registered $scriptBlock
#>
	[CmdletBinding(PositionalBinding = $false, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFRunspace')]
	param
	(
		[Parameter(Mandatory = $true)]
		[Scriptblock]
		$ScriptBlock,
		
		[Parameter(Mandatory = $true)]
		[String]
		$Name,
		
		[switch]
		$NoMessage
	)
	
	if ([PSFramework.Runspace.RunspaceHost]::Runspaces.ContainsKey($Name))
	{
		if (-not $NoMessage) { Write-PSFMessage -Level Verbose -String 'Register-PSFRunspace.Runspace.Updating' -StringValues $Name -Target $Name -Tag 'runspace', 'register' }
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$Name].SetScript($ScriptBlock)
	}
	else
	{
		if (-not $NoMessage) { Write-PSFMessage -Level Verbose -String 'Register-PSFRunspace.Runspace.Creating' -StringValues $Name -Target $Name -Tag 'runspace', 'register' }
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$Name] = New-Object PSFramework.Runspace.RunspaceContainer($Name, $ScriptBlock)
	}
}