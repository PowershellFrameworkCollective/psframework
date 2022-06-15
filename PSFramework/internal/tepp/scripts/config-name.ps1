Register-PSFTeppScriptblock -Name "PSFramework-config-name" -ScriptBlock {
	$moduleName = "*"
	if ($fakeBoundParameter.Module) { $moduleName = $fakeBoundParameter.Module }
	[PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object {
		-not $_.Hidden -and ($_.Module -like $moduleName)
	} | ForEach-Object {
		[PSCustomObject]@{
			Text = $_.Name
			ToolTip = $_.Description
		}
	}
} -Global