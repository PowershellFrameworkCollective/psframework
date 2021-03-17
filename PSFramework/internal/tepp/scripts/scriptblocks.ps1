Register-PSFTeppScriptblock -Name 'PSFramework.Utility.Scriptblock.Name' -ScriptBlock {
	(Get-PSFScriptblock -List).Name
} -Global

Register-PSFTeppScriptblock -Name 'PSFramework.Utility.Scriptblock.Tag' -ScriptBlock {
	(Get-PSFScriptblock -List).Tag | Sort-Object -Unique
} -Global