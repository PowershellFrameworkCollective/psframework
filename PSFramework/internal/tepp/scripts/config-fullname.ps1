Register-PSFTeppScriptblock -Name "PSFramework-config-fullname" -ScriptBlock {
	[PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object {
		-not $_.Hidden
	} | ForEach-Object {
		[PSCustomObject]@{
			Text = $_.FullName
			ToolTip = $_.Description
		}
	}
} -Global