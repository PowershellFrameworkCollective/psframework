function Register-PSFCallback
{
<#
	.SYNOPSIS
		Registers a scriptblock to execute when a command calls Invoke-PSFCallback.
	
	.DESCRIPTION
		Registers a scriptblock to execute when a command calls Invoke-PSFCallback.
		The basic concept of this feature is for a module to offer a registration point,
		where foreign modules - even those unknown to the implementing module - can register
		scriptblocks as delegates. These will then be executed in the implementing module's commands,
		where those call Invoke-PSFCallback.
	
		When designing a callback, keep in mind, that it will be executed on all applicable commmands.
		A major aspect to consider here is the execution time, as this will get added on top of each applicable execution.
	
	.PARAMETER Name
		Name of the callback.
		Must be unique.
	
	.PARAMETER ModuleName
		The name of the module from which Invoke-PSFCallback is being called.
	
	.PARAMETER CommandName
		Name of the command calling Invoke-PSFCallback.
		Allows wildcard matching.
	
	.PARAMETER ScriptBlock
		The scriptblock to execute as callback action.
		This scriptblock will receive a single argument: A hashtable.
		That hashtable will contain the following keys:
		- Command:        Name of the command calling Invoke-PSFCallback
		- ModuleName:     Name of the module the command calling Invoke-PSFCallback is part of.
		- CallerFunction: Name of the command calling the command calling Invoke-PSFCallback
		- CallerModule:   Name of the module of the command calling the command calling Invoke-PSFCallback
		- Data:           Additional data specified by the command calling Invoke-PSFCallback
	
	.PARAMETER Scope
		Whether the callback script is valid in this runspace only (default) or process-wide.
	
	.PARAMETER BreakAffinity
		By default, the callback scriptblock is being executed in the runspace that defined it.
		Setting this parameter, the callback scriptblock is instead being executed in whatever
		runspace it is being triggered from.
	
	.EXAMPLE
		PS C:\> Register-PSFCallback -Name 'MyModule.Configuration' -ModuleName 'DomainManagement' -CommandName '*' -ScriptBlock $ScriptBlock
	
		Defines a callback named 'MyModule.Configuration'.
		This callback scriptblock will be triggered from all commands of the DomainManagement module,
		however only from the current runspace.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ModuleName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$CommandName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[scriptblock]
		$ScriptBlock,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('CurrentRunspace', 'Process')]
		[string]
		$Scope = 'CurrentRunspace',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[switch]
		$BreakAffinity
	)
	
	process
	{
		$callback = New-Object PSFramework.Flowcontrol.Callback -Property @{
			Name		  = $Name
			ModuleName    = $ModuleName
			CommandName   = $CommandName
			BreakAffinity = $BreakAffinity
			ScriptBlock   = $ScriptBlock
		}
		if ($Scope -eq 'CurrentRunspace') { $callback.Runspace = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId }
		[PSFramework.FlowControl.CallbackHost]::Add($callback)
	}
}