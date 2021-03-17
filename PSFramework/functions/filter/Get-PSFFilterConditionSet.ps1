function Get-PSFFilterConditionSet {
<#
	.SYNOPSIS
		Retrieve defined filter condition sets.
	
	.DESCRIPTION
		Retrieve defined filter condition sets.
		Filter condition sets are a grouped set of conditions used in filter expressions.
		Create a filter expression by using New-PSFFilter.
	
	.PARAMETER Module
		The module to filter by.
		Defaults to '*'
	
	.PARAMETER Name
		The name of the condition set to retrieve.
		Defaults to '*'
	
	.PARAMETER Version
		Retrieve a specific version of the filter condition set.
		By default, the latest version only is returned.
	
	.PARAMETER AllVersions
		Retrieve all versions of a given filter condition set.
	
	.EXAMPLE
		PS C:\> Get-PSFFilterConditionSet
	
		List all defined filter condition sets.
	
	.EXAMPLE
		PS C:\> Get-PSFFilterConditionSet -Module PSFramework -Name Environment
	
		Returns the filter condition set "Environment" from the module PSFramework.
#>
	[OutputType([PSFramework.Filter.ConditionSet])]
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('PSFramework.Filter.SetModule')]
		[string]
		$Module = '*',
		
		[PsfArgumentCompleter('PSFramework.Filter.SetName')]
		[string]
		$Name = '*',
		
		[System.Version]
		$Version,
		
		[switch]
		$AllVersions
	)
	
	process {
		$script:filterContainer.FindConditionSet($Module, $Name, $Version, $AllVersions)
	}
}