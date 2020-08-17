Register-PSFTeppScriptblock -Name 'PSFramework.Callback.Name' -ScriptBlock {
	(Get-PSFCallback).Name | Select-Object -Unique
} -Global