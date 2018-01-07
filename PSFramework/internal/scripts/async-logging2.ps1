$scriptBlock = {
	try
	{
		$script:___ScriptName = 'PSFramework.Logging'
		
		while ($true)
		{
			# This portion is critical to gracefully closing the script
			if ([PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLower()].State -notlike "Running")
			{
				break
			}
			
			#region Manage Begin Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetEnabled())
			{
				if (-not $___provider.Initialized)
				{
					$ExecutionContext.InvokeCommand.InvokeScript($false, ([System.Management.Automation.ScriptBlock]::Create($___provider.BeginEvent)), $null, $null)
					$___provider.Initialized = $true
				}
			}
			#endregion Manage Begin Event
			
			#region Start Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
			{
				$ExecutionContext.InvokeCommand.InvokeScript($false, ([System.Management.Automation.ScriptBlock]::Create($___provider.StartEvent)), $null, $null)
			}
			#endregion Start Event
			
			#region Message Event
			while ([PSFramework.Message.LogHost]::OutQueueLog.Count -gt 0)
			{
				$Entry = $null
				[PSFramework.Message.LogHost]::OutQueueLog.TryDequeue([ref]$Entry)
				if ($Entry)
				{
					foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
					{
						if ($___provider.MessageApplies($Entry))
						{
							$ExecutionContext.InvokeCommand.InvokeScript($false, ([System.Management.Automation.ScriptBlock]::Create($___provider.MessageEvent)), $null, $Entry)
						}
					}
				}
			}
			#endregion Message Event
			
			#region Error Event
			while ([PSFramework.Message.LogHost]::OutQueueError.Count -gt 0)
			{
				$Record = $null
				[PSFramework.Message.LogHost]::OutQueueError.TryDequeue([ref]$Record)
				
				if ($Record)
				{
					foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
					{
						if ($___provider.MessageApplies($Record))
						{
							$ExecutionContext.InvokeCommand.InvokeScript($false, ([System.Management.Automation.ScriptBlock]::Create($___provider.MessageEvent)), $null, $Record)
						}
					}
				}
			}
			#endregion Error Event
			
			#region End Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
			{
				$ExecutionContext.InvokeCommand.InvokeScript($false, ([System.Management.Automation.ScriptBlock]::Create($___provider.EndEvent)), $null, $null)
			}
			#endregion End Event
			
			Start-Sleep -Seconds 5
		}
	}
	catch
	{
		
	}
	finally
	{
		#region Final Event
		foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
		{
			$ExecutionContext.InvokeCommand.InvokeScript($false, ([System.Management.Automation.ScriptBlock]::Create($___provider.FinalEvent)), $null, $null)
		}
		
		foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
		{
			$___provider.Initialized = $false
		}
		#endregion Final Event
		
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLower()].SignalStopped()
	}
}

Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'PSFramework.Logging' -NoMessage
Start-PSFRunspace -Name 'PSFramework.Logging' -NoMessage