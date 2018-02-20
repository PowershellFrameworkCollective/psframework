#region Tepp Data return: Config Name
$ScriptBlock = {
	param (
		$commandName,
		
		$parameterName,
		
		$wordToComplete,
		
		$commandAst,
		
		$fakeBoundParameter
	)
	
	$start = Get-Date
	[PSFramework.TabExpansion.TabExpansionHost]::Scripts["config-name"].LastExecution = $start
	
	$moduleName = "*"
	if ($fakeBoundParameter.Module) { $moduleName = $fakeBoundParameter.Module }
	
	foreach ($name in ([PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object { (-not $_.Hidden) -and ($_.Name -Like "$wordToComplete*") -and ($_.Module -like $moduleName) } | Select-Object -ExpandProperty Name | Sort-Object))
	{
		New-PSFTeppCompletionResult -CompletionText $name -ToolTip $name
	}
	[PSFramework.TabExpansion.TabExpansionHost]::Scripts["config-name"].LastDuration = (Get-Date) - $start
}

Register-PSFTeppScriptblock -ScriptBlock $ScriptBlock -Name "PSFramework-config-name"
#endregion Tepp Data return: Config Name