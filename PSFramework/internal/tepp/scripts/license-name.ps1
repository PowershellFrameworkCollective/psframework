Register-PSFTeppScriptblock -Name 'PSFramework-license-name' -ScriptBlock {
	(Get-PSFLicense).Product
} -Global