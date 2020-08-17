Register-PSFTeppScriptblock -Name 'PSFramework.Utility.PathName' -ScriptBlock {
	(Get-PSFConfig "PSFramework.Path.*").Name -replace '^.+\.([^\.]+)$', '$1'
} -Global