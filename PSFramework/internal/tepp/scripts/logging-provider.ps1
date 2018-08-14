Register-PSFTeppScriptblock -Name 'PSFramework-logging-provider' -ScriptBlock {
	(Get-PSFLoggingProvider).Name
}