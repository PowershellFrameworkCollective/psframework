function Get-PSFFilterCondition {
<#
	.SYNOPSIS
		Retrieve defined filter conditions.
	
	.DESCRIPTION
		Retrieve defined filter conditions.
		Filter conditions can be used as part of a condition set, used to evaluate filter expressions defined with New-PSFFilter.
	
	.PARAMETER Module
		The module to filter by.
		Defaults to '*'
	
	.PARAMETER Name
		The name of the condition to retrieve.
		Defaults to '*'
	
	.PARAMETER SetName
		The name of the condition set the condition is assigned to.
		Allows searching by assignment.
	
	.PARAMETER Version
		Retrieve a specific version of the filter condition.
		By default, the latest version only is returned.
	
	.PARAMETER AllVersions
		Retrieve all versions of a given filter condition.
	
	.EXAMPLE
		PS C:\> Get-PSFFilterCondition
	
		List all defined filter conditions.
	
	.EXAMPLE
		PS C:\> Get-PSFFilterCondition -Module PSFramework -Name OSWindows
	
		Returns the filter condition "OSWindows" from the module PSFramework.
#>
	[OutputType([PSFramework.Filter.Condition])]
	[CmdletBinding(DefaultParameterSetName = 'default')]
	param (
		[PsfArgumentCompleter('PSFramework.Filter.Module')]
		[string]
		$Module = '*',
		
		[PsfArgumentCompleter('PSFramework.Filter.Name')]
		[string]
		$Name = '*',
		
		[PsfArgumentCompleter('PSFramework.Filter.SetName')]
		[string]
		$SetName,
		
		[Parameter(ParameterSetName = 'Version')]
		[System.Version]
		$Version,
		
		[Parameter(ParameterSetName = 'AllVersion')]
		[switch]
		$AllVersions
	)
	
	process {
		if ($SetName) {
			Get-PSFFilterConditionSet -Module $Module -Name $SetName | ForEach-Object {
				$_.ConditionTable.Values | Where-Object Name -Like $Name
			}
		}
		else {
			$script:filterContainer.FindCondition($Module, $Name, $Version, $AllVersions)
		}
	}
}