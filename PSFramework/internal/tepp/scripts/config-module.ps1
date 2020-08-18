Register-PSFTeppScriptblock -Name "PSFramework-config-module" -ScriptBlock {
	[PSFramework.Configuration.ConfigurationHost]::Configurations.Values.Module | Select-Object -Unique
} -Global