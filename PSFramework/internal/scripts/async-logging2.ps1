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
					. $___provider.BeginEvent
					$___provider.Initialized = $true
				}
			}
			#endregion Manage Begin Event
			
			#region Start Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
			{
				. $___provider.StartEvent
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
							$___provider.MessageEvent.Invoke($Entry)
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
							$___provider.MessageEvent.Invoke($Record)
						}
					}
				}
			}
			#endregion Error Event
			
			#region End Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
			{
				. $___provider.EndEvent
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
			. $___provider.FinalEvent
		}
		#endregion Final Event
		
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLower()].State = "Stopped"
	}
}

Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'PSFramework.Logging'
Start-PSFRunspace -Name 'PSFramework.Logging'