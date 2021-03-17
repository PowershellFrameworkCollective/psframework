function Invoke-PSFFilter {
<#
	.SYNOPSIS
		Evaluate a filter.
	
	.DESCRIPTION
		Evaluate a filter.
		Can either run all by itself - for example to evaluate the runtime environment - or be given an argument to evaluate it against the expression.
	
		Use ...
		- New-PSFFilter to customize a filter
		- New-PSFFilterCondition to architect your own conditions for use in expressions.
		- New-PSFFilterConditionSet to tie conditions together into a set
		Each filter must have a condition set assigned to be able to run (as otherwise it will not know which conditions are available).
	
		This function exists mostly for discoverability.
		Filter objects returned by New-PSFFilter can be invoked directly using their .Evaluate() method, providing far greater performance at scale.
	
	.PARAMETER Expression
		The filter expression to execute.
		Can only consist of:
		- Names of conditions: Words (may contain letters, numbers and underscore, but no dash)
		- Parenthesis
		- Logical operators (-or, -and, -not, -xor)
	
	.PARAMETER ArgumentList
		Any argument to specify as input to the filter expression.
		All input is passed as one item, to evaluate against multiple items separately, loop the entire command.
		Note: To avoid incurring the overhead for large datasets, filter objects returned by New-PSFFilter can be invoked directly using the .Evaluate() method which also accepts arguments.
	
	.PARAMETER Filter
		The filter object to invoke.
		Objects of this type can be created by New-PSFFilter.
	
	.PARAMETER ConditionSet
		A full Condition Set object as returned by Get-PSFConditionSet.
	
	.PARAMETER SetModule
		Name of the module in which to search for a Condition Set.
	
	.PARAMETER SetName
		Name of the Condition Set to use.
	
	.EXAMPLE
		PS C:\> Invoke-PSFFilter -Expression 'OSWindows -or EnvAzurePipelines' -SetModule PSFramework -SetName Environment
	
		Executes the specified filter expression using the Environment ConditionSet from the PSFramework module.
		Will return true if executed either on Windows or from within Azure DevOps Pipelines
#>
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'ExpressionObject')]
		[Parameter(Mandatory = $true, ParameterSetName = 'ExpressionName')]
		[string]
		$Expression,
		
		$ArgumentList,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
		[PSFramework.Filter.Expression]
		$Filter,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'ExpressionObject')]
		[Parameter(ParameterSetName = 'Filter')]
		[PSFramework.Filter.ConditionSet]
		$ConditionSet,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'ExpressionName')]
		[Parameter(ParameterSetName = 'Filter')]
		[PsfArgumentCompleter('PSFramework.Filter.SetModule')]
		[string]
		$SetModule,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'ExpressionName')]
		[Parameter(ParameterSetName = 'Filter')]
		[PsfArgumentCompleter('PSFramework.Filter.SetName')]
		[string]
		$SetName
	)
	
	begin {
		if ($SetModule -and -not $SetName) {
			Invoke-PsfTerminatingException -Message 'Cannot specify -SetModule without -SetName' -ErrorId 'InvalidArgument' -Category InvalidArgument -Cmdlet $PSCmdlet
		}
		if (-not $SetModule -and $SetName) {
			Invoke-PsfTerminatingException -Message 'Cannot specify -SetName without -SetModule' -ErrorId 'InvalidArgument' -Category InvalidArgument -Cmdlet $PSCmdlet
		}
	}
	process {
		$filterObject = $null
		if ($Filter) {
			$filterObject = $Filter.Clone()
			if ($ConditionSet) { $filterObject.ConditionSet = $ConditionSet }
			if ($SetModule -and $SetName) {
				$filterObject.ConditionSet = $script:filterContainer.GetConditionSet($SetModule, $SetName)
			}
		}
		if ($Expression) {
			$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Expression, ConditionSet, SetModule, SetName
			try { $filterObject = New-PSFFilter @parameters }
			catch { throw }
		}
		if (-not $filterObject.ConditionSet) {
			Invoke-PsfTerminatingException -Message 'Filters must have a Condition Set in order to evaluate them!' -ErrorId 'NoConditionSet' -Category InvalidArgument -TargetObject $filterObject -Cmdlet $PSCmdlet
		}
		
		# Can only fail if the condition scriptblocks are written badly
		try { $filterObject.Evaluate($ArgumentList) }
		catch { throw }
	}
}