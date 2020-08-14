Register-PSFTeppScriptblock -Name 'PSFramework-Config-Schema' -ScriptBlock {
	[PSFramework.Configuration.ConfigurationHost]::Schemata.Keys
} -Global