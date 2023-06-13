Register-PSFTeppScriptblock -Name 'PSFramework.Utility.ParameterSetNames' -ScriptBlock {
	$referenceCommandName = $fakeBoundParameter.ReferenceCommand
	if (-not $referenceCommandName) { return }

	$commandInfo = Get-Command -Name $referenceCommandName -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\Select-Object -First 1
	if (-not $commandInfo) { return }

	$commandInfo.ParameterSets.Name
} -Global