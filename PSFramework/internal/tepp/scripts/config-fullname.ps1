#region Tepp Data return: FullName
$ScriptBlock = {
	param (
		$commandName,
		
		$parameterName,
		
		$wordToComplete,
		
		$commandAst,
		
		$fakeBoundParameter
	)
	
	$start = Get-Date
	[PSFramework.TabExpansion.TabExpansionHost]::Scripts["config-fullname"].LastExecution = $start
	
	foreach ($name in ([PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object { -not $_.Hidden -and ($_.FullName -Like "$wordToComplete*") } | Select-Object -ExpandProperty FullName | Sort-Object))
	{
		New-PSFTeppCompletionResult -CompletionText $name -ToolTip $name
	}
	[PSFramework.TabExpansion.TabExpansionHost]::Scripts["config-fullname"].LastDuration = (Get-Date) - $start
}

Register-PSFTeppScriptblock -ScriptBlock $ScriptBlock -Name "PSFramework-config-fullname"
#endregion Tepp Data return: FullName