Register-PSFTeppScriptblock -Name 'PSFramework-runspace-name' -ScriptBlock {
	(Get-PSFRunspace).Name
} -Global