Register-PSFTeppScriptblock -Name 'PSFramework-runspace-name' -ScriptBlock {
	(Get-PSFRunspace).Name
} -Global

Register-PSFTeppScriptblock -Name 'PSFramework-runspace-workflow-name' -ScriptBlock {
	(Get-PSFRunspaceWorkflow).Name
} -Global