Register-PSFTeppScriptblock -Name 'PSFramework-logging-provider' -ScriptBlock {
	(Get-PSFLoggingProvider).Name
}

Register-PSFTeppScriptblock -Name 'PSFramework-logging-instance-provider' -ScriptBlock {
	(Get-PSFLoggingProviderInstance).Provider.Name | Select-Object -Unique
}

Register-PSFTeppScriptblock -Name 'PSFramework-logging-instance-name' -ScriptBlock {
	if ($fakeBoundParameters.ProviderName)
	{
		return (Get-PSFLoggingProviderInstance -ProviderName $fakeBoundParameters.ProviderName).Name
	}
	(Get-PSFLoggingProviderInstance).Name | Select-Object -Unique
}