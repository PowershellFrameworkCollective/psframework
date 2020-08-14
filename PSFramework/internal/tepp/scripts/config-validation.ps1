Register-PSFTeppScriptblock -Name 'PSFramework-config-validation' -ScriptBlock {
	[PSFramework.Configuration.ConfigurationHost]::Validation.Keys
} -Global