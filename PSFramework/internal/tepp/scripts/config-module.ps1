#region Tepp Data return: Module Name
$ScriptBlock = {
	param (
		$commandName,
		
		$parameterName,
		
		$wordToComplete,
		
		$commandAst,
		
		$fakeBoundParameter
	)
	
	$start = Get-Date
	[PSFramework.TabExpansion.TabExpansionHost]::Scripts["config-module"].LastExecution = $start
	
	foreach ($name in ([PSFramework.Configuration.ConfigurationHost]::Configurations.Values.Module | Select-Object -Unique | Where-Object { $_ -Like "$wordToComplete*" } | Sort-Object))
	{
		New-PSFTeppCompletionResult -CompletionText $name -ToolTip $name
	}
	[PSFramework.TabExpansion.TabExpansionHost]::Scripts["config-module"].LastDuration = (Get-Date) - $start
}

Register-PSFTeppScriptblock -ScriptBlock $ScriptBlock -Name "config-module"
#endregion Tepp Data return: Module Name