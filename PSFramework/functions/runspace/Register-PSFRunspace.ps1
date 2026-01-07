function Register-PSFRunspace
{
<#
	.SYNOPSIS
		Registers a scriptblock to run in the background.
	
	.DESCRIPTION
		This function registers a scriptblock to run in separate runspace.
		This is different from most runspace solutions, in that it is designed for permanent background tasks that need to be done.
		It guarantees a single copy of the task to run within the powershell process, even when running the same module in many runspaces in parallel.
		
		There are two Generations of the Managed Runspace system available:
		Gen 1: -ScriptBlock | Full control over the execution, but some integrations are required for the whole thing to work.
		Gen 2: -Begin/-Process/-End | Simple execution that is easy to use, but surrenders some control over the process.
		
		The full documentation can be found online: https://psframework.org
		By default, using the Generation 2 implementation is recommended, the third shows how to use it.		
	
		Updating:
		If this function is called multiple times, targeting the same name, it will update the scriptblock.
		- If that scriptblock is the same as the previous scriptblock, nothing changes
		- If that scriptblock is different from the previous ones, it will be registered, but will not be executed right away!
		  Only after stopping and starting the runspace will it operate under the new scriptblock.
	
	.PARAMETER Name
		The name to register the scriptblock under.
	
	.PARAMETER ScriptBlock
		The scriptblock to run in a dedicated runspace.
		Scriptblock must be trusted and not in Constrained Language Mode.

	.PARAMETER Begin
		The startup phase in a Generation 2 Managed Runspace.
		Will be executed once in the managed runspace and will run in the global scope.
		Scriptblock must be trusted and not in Constrained Language Mode.

	.PARAMETER Process
		The main processing phase in a Generation 2 Managed Runspace.
		Will be executed repeatedly until the Managed Runspace is stopped.
		There is a 250ms wait inbetween executions, to prevent CPU overload, additional waiting can be performed within the code.
		To stop the entire Managed Runspace from within your code, call "break" - this will not prevent the End phase from executing if specified.

	.PARAMETER End
		The end phase in a Generation 2 Managed Runspace.
		Will be executed once at the end when stopping the Managed Runspace
	
	.PARAMETER NoMessage
		Setting this will prevent messages be written to the message / logging system.
		This is designed to make the PSFramework not flood the log on each import.

	.PARAMETER Start
		Automatically start the runspace after registering it.
	
	.EXAMPLE
		PS C:\> Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'mymodule.maintenance'
	
		Registers the script defined in $scriptBlock under the name 'mymodule.maintenance'
		It does not start the runspace yet. If it already exists, it will overwrite the scriptblock without affecting the running script.
	
	.EXAMPLE
		PS C:\> Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'mymodule.maintenance'
		PS C:\> Start-PSFRunspace -Name 'mymodule.maintenance'
	
		Registers the script defined in $scriptBlock under the name 'mymodule.maintenance'
		Then it starts the runspace, running the registered $scriptBlock

	.EXAMPLE
		PS C:\> $code = { Remove-Item -Path "$env:TEMP\MyModule-*" -Force -Recurse; Start-Sleep -Seconds 30 }
		PS C:\> Register-PSFRunspace -Name 'mymodule.tempcleaner' -Process $code -Start

		Creates a background runspace that can never exist more than once in the current process.
		It will clean all items under $env:TEMP that start with "MyModule-" every 30 seconds (plus 250ms, which are added by the system).
#>
	[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'Gen2', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFRunspace')]
	param
	(
		[Parameter(Mandatory = $true)]
		[String]
		$Name,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Gen1')]
		[PSFramework.Validation.PsfValidateLanguageMode()]
		[Scriptblock]
		$ScriptBlock,

		[Parameter(ParameterSetName = 'Gen2')]
		[PSFramework.Validation.PsfValidateLanguageMode()]
		[Scriptblock]
		$Begin,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Gen2')]
		[Scriptblock]
		$Process,
		
		[Parameter(ParameterSetName = 'Gen2')]
		[Scriptblock]
		$End,
		
		[switch]
		$NoMessage,

		[switch]
		$Start
	)

	switch ($PSCmdlet.ParameterSetName) {
		Gen1 { $wasNew = [PSFramework.Runspace.RunspaceHost]::SetManagedRunspace($Name, $ScriptBlock) }
		Gen2 { $wasNew = [PSFramework.Runspace.RunspaceHost]::SetManagedRunspace($Name, $Begin, $Process, $End) }
	}
	
	if (-not $NoMessage) {
		if (-not $wasNew)
		{
			Write-PSFMessage -Level Verbose -String 'Register-PSFRunspace.Runspace.Updating' -StringValues $Name -Target $Name -Tag 'runspace', 'register'
		}
		else
		{
			Write-PSFMessage -Level Verbose -String 'Register-PSFRunspace.Runspace.Creating' -StringValues $Name -Target $Name -Tag 'runspace', 'register'
		}
	}
	
	if ($Start) {
		Start-PSFRunspace -Name $Name -NoMessage:$NoMessage
	}
}