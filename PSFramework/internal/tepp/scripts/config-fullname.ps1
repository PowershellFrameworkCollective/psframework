Register-PSFTeppScriptblock -Name "PSFramework-config-fullname" -ScriptBlock {
	[PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object { -not $_.Hidden } | Select-Object -ExpandProperty FullName
}