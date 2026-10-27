function Clear-PSFMessage {
<#
	.SYNOPSIS
		Clears the in-memory log of the message system, or the inmemory logs by the inmemory Logging Provider.
	
	.DESCRIPTION
		Clears the in-memory log of the message system, or the inmemory logs by the inmemory Logging Provider.
		Has no effect on written logfiles, table entries, eventlog logs or wherever else you may be logging.

		Defaults to the message system memory log unless specified.

	.PARAMETER LogName
		The name of the inmemory log to clear.
		Maps to the InstanceName of the inmemory Logging Provider.
	
	.EXAMPLE
		PS C:\> Clear-PSFMessage
	
		Clears the in-memory log of the message system.

	.EXAMPLE
		PS C:\> Clear-PSFMessage -LogName user-mgmt-log-max

		Clears all in-memory logs of the 'user-mgmt-log-max' inmemory Logging Provider
#>
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('PSFramework.Logging.InMemoryLogName')]
		[string]
		$LogName
	)
	
	process {
		if (-not $LogName) {
			[PSFramework.Message.LogHost]::ClearLog()
			return
		}

		$allLogs = [PSFramework.Message.LogHost]::InMemoryLogs.Values, [PSFramework.Message.LogHost]::InMemoryLogsArchive.Values | Write-Output | Where-Object {
			$_.ID -eq $LogName -or
			$_.Name -eq $LogName
		}
		foreach ($log in $allLogs) { $log.Clear() }
	}
}