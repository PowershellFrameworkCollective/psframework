Register-PSFTeppScriptblock -Name "PSFramework.Feature.Name" -ScriptBlock {
	(Get-PSFFeature).Name
} -Global