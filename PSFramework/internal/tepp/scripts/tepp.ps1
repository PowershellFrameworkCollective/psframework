Register-PSFTeppScriptblock -Name 'PSFramework-tepp-scriptblockname' -ScriptBlock {
	[PSFramework.TabExpansion.TabExpansionHost]::Scripts.Keys
} -Global

Register-PSFTeppScriptblock -Name 'PSFramework-tepp-parametername' -ScriptBlock {
	if ($fakeBoundParameter.Command)
	{
		$common = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'WhatIf', 'Confirm'
		
		try
		{
			$command = Get-Command $fakeBoundParameter.Command
			if ($command -is [System.Management.Automation.AliasInfo]) { $command = $command.ResolvedCommand }
			$command.Parameters.Keys | Where-Object { $_ -notin $common }
		}
		catch { }
	}
} -Global