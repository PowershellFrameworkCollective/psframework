function New-PSFFilterConditionSet {
<#
	.SYNOPSIS
		Create a new filter condition set.
	
	.DESCRIPTION
		Create a new filter condition set.
		A filter condition set is a grouping of filter conditions.
		These sets are referenced when creating or invoking a filter expression and are the logic implementation used to evaluate the expression.
	
		Individual filter conditions can be added, and ...
		- Not all Conditions in a set need be used in any given Filter expression using that set.
		- Not all Conditions must be from the same module as the Condition Set.
	
	.PARAMETER Module
		The module that owns the filter condition set.
	
	.PARAMETER Name
		The name of the filter condition set.
		This name is unique within any given module.
	
	.PARAMETER Version
		The version of the filter condition set.
		You can provide multiple versions of a set for backwards compatiblity, however selecting the correct version for your expressions is your own responsibility.
		Defaults to 1.0.0
	
	.PARAMETER Conditions
		The conditions that are part of the Condition Set.
		These are the individual technical implementations used to evaluate a fitler expression.
		Use New-PSFFilterCondition to define these objects or Get-PSFFilterCondition to retrieve already defined objects.
	
	.PARAMETER ScriptBlock
		A Scriptblock that will be executed and all Filter Condition objects returned will become part of the set.
		This allows combining the definition of a Condition Set and its component Conditions into a single call.
	
	.EXAMPLE
		PS C:\> New-PSFFilterConditionSet -Module 'Bartender' -Name 'Alcohols'
	
		Defines a new Condition Set named Alcohols in the module Bartender.
		This set is created empty and must later be filled with Conditions before using it.
	
	.EXAMPLE
		PS C:\> Get-PSFFilterCondition -Module Bartender | New-PSFFilterConditionSet -Module 'Bartender' -Name 'Alcohols'
	
		Defines a new Condition Set named Alcohols in the module Bartender.
		Adds all Conditions defined in the same module to it.
	
	.EXAMPLE
		PS C:\> New-PSFFilterConditionSet -Module 'Bartender' -Name 'Alcohols' -ScriptBlock {
			New-PSFFilterCondition -Module Bartender -Name Beer -ScriptBlock { $_.Type -eq 'Beer' }
			New-PSFFilterCondition -Module Bartender -Name Vodka -ScriptBlock { $_.Type -eq 'Vodka' }
			New-PSFFilterCondition -Module Bartender -Name Whiskey -ScriptBlock { $_.Type -eq 'Whiskey' }
			New-PSFFilterCondition -Module Bartender -Name Rum -ScriptBlock { $_.Type -eq 'Rum' }
		}
	
		Defines a new Condition Set named Alcohols in the module Bartender.
		Adds the four newly created Coditions straight to the Set.
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([PSFramework.Filter.ConditionSet])]
	[CmdletBinding(DefaultParameterSetName = 'default')]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('PSFramework.Filter.SetModule')]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[System.Version]
		$Version = '1.0.0',
		
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Objects')]
		[PSFramework.Filter.Condition[]]
		$Conditions,
		
		[Parameter(ParameterSetName = 'Scriptblock')]
		[System.Management.Automation.ScriptBlock]
		$ScriptBlock
	)
	
	begin {
		$conditionObjects = [System.Collections.ArrayList]@()
	}
	process {
		if ($Conditions) {
			$conditionObjects.AddRange($Conditions)
		}
		if ($ScriptBlock) {
			try { $results = & $ScriptBlock }
			catch { throw }
			foreach ($result in $results) {
				if ($result -isnot [PSFramework.Filter.Condition]) { continue }
				$null = $conditionObjects.Add($result)
			}
		}
	}
	end {
		$script:filterContainer.AddConditionSet($Module, $Name, $Version, $conditionObjects.ToArray())
	}
}