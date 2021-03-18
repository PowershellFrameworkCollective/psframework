function Test-PSFFilter {
<#
	.SYNOPSIS
		Tests a filter expression on whether it is valid.
	
	.DESCRIPTION
		Tests a filter expression on whether it is valid.
		Can also validate, that it will work with the specified condition set.
	
	.PARAMETER Expression
		The filter expression to validate.
	
	.PARAMETER ConditionSet
		The condition set object (as returned by Get-PSFFilterConditionSet) to validate against the expression.
	
	.PARAMETER SetModule
		The name of the module from which to pick up the condition set to validate against the expression.
	
	.PARAMETER SetName
		The name of the condition set to validate against the expression.
	
	.EXAMPLE
		PS C:\> Test-PSFFilter -Expression 'OSWindows -or EnvAzurePipelines'
	
		Validates the syntax of the "OSWindows -or EnvAzurePipelines" expression (which is correct).
	
	.EXAMPLE
		PS C:\> Test-PSFFilter -Expression 'OSWindows -or EnvAzurePipelines' -SetModule PSFramework -SetName Environment
	
		Validates the syntax of the "OSWindows -or EnvAzurePipelines" expression (which is correct).
		It then compares it to the latest version of the Environment ConditionSet from within the PSFramework and validates, that it contains the conditions used in the expression ("OSWindows" and "EnvAzurePipelines").
#>
	[OutputType([bool])]
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
		[string]
		$SetName
	)
	
	process {
		$conditionSetObject = $null
		if ($SetModule -or $ConditionSet) {
			$conditionSetObject = Resolve-PsfFilterConditionSet -ConditionSet $ConditionSet -SetModule $SetModule -SetName $SetName -Cmdlet $PSCmdlet
		}
		
		try { $filter = New-Object PSFramework.Filter.Expression($Expression, $conditionSetObject) }
		catch { return $false }
		
		if (-not $conditionSetObject) { return $true }
		
		$success = $true
		foreach ($condition in $filter.Conditions) {
			if ($conditionSetObject.Conditions.Name -contains $condition) { continue }
			Write-PSFMessage -Level Verbose -String 'Test-PSFFilter.Condition.NotInSet' -StringValues $condition -Target $filter
			$success = $false
		}
		return $success
	}
}