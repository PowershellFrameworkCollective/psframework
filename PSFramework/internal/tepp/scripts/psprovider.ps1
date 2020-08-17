Register-PSFTeppScriptblock -Name 'PSFramework-utility-psprovider' -ScriptBlock {
	(Get-PSProvider).Name
} -Global