Register-PSFTeppScriptblock -Name "PSFramework.Filter.Module" -ScriptBlock {
	(Get-PSFFilterCondition).Module | Select-Object -Unique
} -Global

Register-PSFTeppScriptblock -Name "PSFramework.Filter.SetModule" -ScriptBlock {
	(Get-PSFFilterConditionSet).Module | Select-Object -Unique
} -Global

Register-PSFTeppScriptblock -Name "PSFramework.Filter.Name" -ScriptBlock {
	$module = '*'
	if ($fakeBoundParameters.Module) { $module = $fakeBoundParameters.Module }
	(Get-PSFFilterCondition -Module $module).Name | Select-Object -Unique
} -Global

Register-PSFTeppScriptblock -Name "PSFramework.Filter.SetName" -ScriptBlock {
	$module = '*'
	if ($fakeBoundParameters.Module) { $module = $fakeBoundParameters.Module }
	if ($fakeBoundParameters.SetModule) { $module = $fakeBoundParameters.SetModule }
	(Get-PSFFilterConditionSet -Module $module).Name | Select-Object -Unique
} -Global