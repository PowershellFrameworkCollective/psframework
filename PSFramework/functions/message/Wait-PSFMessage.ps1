function Wait-PSFMessage
{
<#
	.SYNOPSIS
		Waits until the PSFramework log queue has been flushed.
	
	.DESCRIPTION
		Waits until the PSFramework log queue has been flushed.
		Also supports ending the logging runspace.
	
		This is designed to explicitly handle script termination for tasks that run in custom hosts that do not properly fire runspace termination events, leading to infinitely hanging tasks.
	
	.PARAMETER Timeout
		Maximum duration for the command to wait until it terminates even if there are messages left.
	
	.PARAMETER Terminate
		If this parameter is specified it will terminate the running logging runspace.
		Use this if your script will run in a powershell host that does not properly execute termination events.
		Danger!!!! Should never be used in a script that might be called by other scripts, as this might prematurely end logging!
	
	.EXAMPLE
		PS C:\> Wait-PSFMessage
	
		Waits until all pending messages are logged.
	
	.EXAMPLE
		PS C:\> Wait-PSFMessage -Timeout 1m -Terminate
	
		Waits up to one minute for all messages to be flushed, then terminates the logging runspace
#>
	[CmdletBinding()]
	param (
		[PSFDateTime]
		$Timeout = "5m",
		
		[switch]
		$Terminate
	)
	
	process
	{
		if (([PSFramework.Message.LogHost]::OutQueueLog.Count -gt 0) -or ([PSFramework.Message.LogHost]::OutQueueError.Count -gt 0))
		{
			if ((Get-PSFRunspace -Name 'psframework.logging') -notlike 'Running') { Start-PSFRunspace -Name 'psframework.logging' }
		}
		while ($Timeout.Value -gt (Get-Date))
		{
			if (([PSFramework.Message.LogHost]::OutQueueLog.Count -eq 0) -and ([PSFramework.Message.LogHost]::OutQueueError.Count -eq 0))
			{
				break
			}
			Start-Sleep -Milliseconds 250
		}
		
		# To ensure enough time between message dequeue has passed and all write events were finished.
		Start-Sleep -Seconds 3
		
		if ($Terminate)
		{
			Stop-PSFRunspace -Name 'psframework.logging'
		}
	}
}