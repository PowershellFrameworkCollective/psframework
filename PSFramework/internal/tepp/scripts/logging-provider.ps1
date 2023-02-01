Register-PSFTeppScriptblock -Name 'PSFramework-logging-provider' -ScriptBlock {
	(Get-PSFLoggingProvider).Name
} -Global

Register-PSFTeppScriptblock -Name 'PSFramework-logging-instance-provider' -ScriptBlock {
	(Get-PSFLoggingProviderInstance).Provider.Name | Select-Object -Unique
} -Global

Register-PSFTeppScriptblock -Name 'PSFramework-logging-instance-name' -ScriptBlock {
	if ($fakeBoundParameters.ProviderName)
	{
		return (Get-PSFLoggingProviderInstance -ProviderName $fakeBoundParameters.ProviderName).Name
	}
	(Get-PSFLoggingProviderInstance).Name | Select-Object -Unique
} -Global

Register-PSFTeppScriptblock -Name 'PSFramework-logging-instance-name2' -ScriptBlock {
	if ($fakeBoundParameters.Name)
	{
		return (Get-PSFLoggingProviderInstance -ProviderName $fakeBoundParameters.ProviderName).Name
	}
	(Get-PSFLoggingProviderInstance).Name | Select-Object -Unique
} -Global