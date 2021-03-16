function New-PSFFilterCondition {
	[OutputType([PSFramework.Filter.Condition])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
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