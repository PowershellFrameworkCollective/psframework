function Get-PSFFilterConditionSet {
	[OutputType([PSFramework.Filter.ConditionSet])]
	[CmdletBinding()]
	param (
		[string]
		$Module = '*',
		
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