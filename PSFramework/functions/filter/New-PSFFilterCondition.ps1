function New-PSFFilterCondition {
<#
	.SYNOPSIS
		Create a new filter condition used in filter expressions.
	
	.DESCRIPTION
		Create a new filter condition used in filter expressions.
		A filter condition is a named scriptblock that is designed evaluates either the environment or an input object.
		It should never throw an exception and instead return $true or $false.
		
		Using a filter expression then allows the user to dynamically build a truth statement by combining any number of conditions through boolean operators.
	
	.PARAMETER Module
		The module that owns/defines the condition.
		Use your own module's name to avoid conflicting with foreign modules.
	
	.PARAMETER Name
		The name of the condition.
		Can only contain letters, numbers and underscore.
		A name is unique within a module.
	
	.PARAMETER ScriptBlock
		The scriptblock that is used to execute the condition.
		This scriptblock is bound to the context that defined it and thus runspace specific.
		This means, if you define it within your module, it will have access to module interna, such as private functions.
	
	.PARAMETER Version
		The version number of the condition.
		There can exist multiple versions of a condition at any given time, but only version can exist in a single Condition Set.
		Defaults to 1.0.0
	
	.PARAMETER Type
		What kind of condition is this:
		Static:
		A condition that will not change during the runtime of the process.
	    For example the operating system. Static conditions are executed only once on their first run.
	
		Dynamic:
		Dynamic conditions will be executed every single time an expression that uses it is evaluated.
		Note: An expression may use the same condition multiple times, but it will still only be run once.
	
	.EXAMPLE
		PS C:\> New-PSFFilterCondition -Module 'MyModule' -Name 'HasTemp' -ScriptBlock { Test-Path -Path C:\temp }
	
		Creates a condition named "HasTemp" that is part of the MyModule module.
		When executed, it will validate, whether the temp folder exists.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([PSFramework.Filter.Condition])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('PSFramework.Filter.Module')]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true)]
		[PsfValidateScript('PSFramework.Validate.Filter.ConditionName', ErrorString = 'PSFramework.Validate.Filter.ConditionName')]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[PSFramework.Utility.PsfScriptBlock]
		$ScriptBlock,
		
		[System.Version]
		$Version = '1.0.0',
		
		[PSFramework.Filter.ConditionType]
		$Type = [PSFramework.Filter.ConditionType]::Dynamic
	)
	
	process
	{
		try { $script:filterContainer.AddCondition($Module, $Name, $ScriptBlock, $Version, $Type) }
		catch { throw }
	}
}