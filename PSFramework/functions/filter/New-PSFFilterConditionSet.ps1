function New-PSFFilterConditionSet {
	[OutputType([PSFramework.Filter.ConditionSet])]
	[CmdletBinding(DefaultParameterSetName = 'default')]
	param (
		[Parameter(Mandatory = $true)]
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
	
	begin
	{
		$conditionObjects = [System.Collections.ArrayList]@()
	}
	process
	{
		if ($Conditions) {
			$conditionObjects.AddRange($Conditions)
		}
		if ($ScriptBlock) {
			try { $results = & $ScriptBlock }
			catch { throw }
			foreach ($result in $results) {
				if ($result -isnot [PSFramework.Filter.ConditionSet]) { continue }
				$null = $conditionObjects.Add($result)
			}
		}
	}
	end
	{
		$script:filterContainer.AddConditionSet($Module, $Name, $Version, $conditionObjects.ToArray())
	}
}