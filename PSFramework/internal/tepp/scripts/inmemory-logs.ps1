Register-PSFTeppScriptblock -Name 'PSFramework.Logging.InMemoryLogName' -ScriptBlock {
	$groups = [PSFramework.Message.LogHost]::InMemoryLogs.Values, [PSFramework.Message.LogHost]::InMemoryLogsArchive.Values | Write-Output | Group-Object Name | Sort-Object Name
	foreach ($group in $groups) {
		if ($group.Count -eq 1) {
			@{ Text = $group.Name; Tooltip = 'ID: {0} | Started: {1:HH:mm:ss} | Count: {2} | Archived: {3}' -f $group.Group.ID, $group.Group.Started, $group.Group[0].Count, $group.Group.Archived }
			continue
		}

		@{ Text = $group.Name; Tooltip = $group.Group.ForEach{ 'ID: {0} | Started: {1:HH:mm:ss} | Count: {2} | Archived: {3}' -f $_.ID, $_.Started, $_.Count, $_.Archived } -join "`n" }
		foreach ($entry in $group.Group) {
			@{ Text = $entry.ID; Tooltip = 'Name: {0} | Started: {1:HH:mm:ss} | Count: {2} | Archived: {3}' -f $entry.Name, $entry.Started, $entry.Count, $entry.Archived }
		}
	}
} -Global