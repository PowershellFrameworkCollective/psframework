function New-PSFFilter
{
<#
	.SYNOPSIS
		Creates a new filter object.
	
	.DESCRIPTION
		Creates a new filter object based off the specified expression.
		Optionally, an associated condition set can be specified, either as object or by name and module.
		Conditions Set contain the implementation of the condition logic, that will be used when evaluating the filter expression.
	
		These filter objects can then be used to execute validation either statically or against input objects.
		Combined with filter conditions and condition sets, filters allow defining a custom filter syntax that is easy to write humanly readable filter expressions for without exposing direct code execution.
		This makes filter expressions suitable for data regions and makes conditions easily reusable.
	
	.PARAMETER Expression
		The expression to build a filter object for.
		Can only consist of:
		- Names of conditions: Words (may contain letters, numbers and underscore, but no dash)
		- Parenthesis
		- Logical operators (-or, -and, -not, -xor)
	
	.PARAMETER ConditionSet
		A condition set object to attach to the filter.
	
	.PARAMETER SetModule
		The name of the module from which to select the condition set to attach to the filter.
	
	.PARAMETER SetName
		The name of the condition set to attach to the filter.
	
	.EXAMPLE
		PS C:\> New-PSFFilter -Expression 'OSWindows -or EnvAzurePipelines'
	
		Creates a filter object around the "OSWindows -or EnvAzurePipelines" expression.
	
	.EXAMPLE
		PS C:\> New-PSFFilter -Expression 'OSWindows -or EnvAzurePipelines' -SetModule PSFramework -SetName Environment
	
		Creates a filter object around the "OSWindows -or EnvAzurePipelines" expression.
		It then attaches the latest version of the Environment ConditionSet from within the PSFramework module.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
	[OutputType([PSFramework.Filter.Expression])]
	[CmdletBinding(DefaultParameterSetName = 'default')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Expression,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Object')]
		[PSFramework.Filter.ConditionSet]
		$ConditionSet,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[PsfArgumentCompleter('PSFramework.Filter.SetModule')]
		[string]
		$SetModule,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[PsfArgumentCompleter('PSFramework.Filter.SetName')]
		[string]
		$SetName
	)
	
	process {
		$conditionSetObject = $null
		if ($ConditionSet -or $SetName) {
			$conditionSetObject = Resolve-PsfFilterConditionSet -ConditionSet $ConditionSet -SetModule $SetModule -SetName $SetName -Cmdlet $PSCmdlet
		}
		
		try { New-Object PSFramework.Filter.Expression($Expression, $conditionSetObject) }
		catch { $PSCmdlet.ThrowTerminatingError($_) }
	}
}