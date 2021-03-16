function Get-PSFFilterCondition {
	[OutputType([PSFramework.Filter.Condition])]
	[CmdletBinding()]
	Param (
		[string]
		$Module = '*',
		
		[string]
		$Name = '*',
		
		[System.Version]
		$Version,
		
		[switch]
		$AllVersions
	)
	
	process
	{
		$script:filterContainer.FindCondition($Module, $Name, $Version, $AllVersions)
	}
}