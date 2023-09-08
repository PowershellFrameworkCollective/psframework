$scriptBlock = {
	try
	{
		$script:___ScriptName = 'PSFramework.Logging'
		
		Import-Module (Join-Path ([PSFramework.PSFCore.PSFCoreHost]::ModuleRoot) 'PSFramework.psd1')
		
		while ($true)
		{
			# This portion is critical to gracefully closing the script
			if ([PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName].State -notlike "Running")
			{
				break
			}
			if (-not ([PSFramework.Message.LogHost]::LoggingEnabled)) { break }
			
			# Create instances as needed on cycle begin
			[PSFramework.Logging.ProviderHost]::NextCycle()
			[PSFramework.Logging.ProviderHost]::UpdateAllInstances()
			
			#region Manage Begin Event
			#region V1 providers
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetEnabled())
			{
				if ($___provider.Initialized) { continue }
				
				[PSFramework.Logging.ProviderHost]::LoggingState = 'Initializing'
				$___provider.LocalizeEvents()
				
				try
				{
					$null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.BeginEvent, $null, $null)
					$___provider.Initialized = $true
				}
				catch { $___provider.Errors.Push($_) }
			}
			#endregion V1 providers
			
			#region V2 provider Instances
			foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetEnabledInstances())
			{
				if ($___instance.Initialized) { continue }
				
				[PSFramework.Logging.ProviderHost]::LoggingState = 'Initializing'
				
				try
				{
					$null = & $___instance.BeginCommand
					$___instance.Initialized = $true
				}
				catch { $___instance.AddError($_)}
			}
			#endregion V2 provider Instances
			
			[PSFramework.Logging.ProviderHost]::LoggingState = 'Ready'
			#endregion Manage Begin Event
			
			#region Start Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
			{
				try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.StartEvent, $null, $null) }
				catch { $___provider.Errors.Push($_) }
			}
			foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
			{
				try { $null = & $___instance.StartCommand }
				catch { $___instance.AddError($_) }
			}
			#endregion Start Event
			
			#region Message Event
			while ([PSFramework.Message.LogHost]::OutQueueLog.Count -gt 0)
			{
				$Entry = $null
				$null = [PSFramework.Message.LogHost]::OutQueueLog.TryDequeue([ref]$Entry)
				if ($Entry)
				{
					[PSFramework.Logging.ProviderHost]::LoggingState = 'Writing'
					foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
					{
						if ($___provider.MessageApplies($Entry))
						{
							try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.MessageEvent, $null, $Entry) }
							catch { $___provider.Errors.Push($_) }
						}
					}
					
					foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
					{
						if ($___instance.MessageApplies($Entry))
						{
							try { $null = & $___instance.MessageCommand $Entry }
							catch { $___instance.AddError($_) }
						}
					}
				}
				[PSFramework.Message.LogHost]::LastLogged = [DateTime]::Now
			}
			#endregion Message Event
			
			#region Error Event
			while ([PSFramework.Message.LogHost]::OutQueueError.Count -gt 0)
			{
				$Record = $null
				$null = [PSFramework.Message.LogHost]::OutQueueError.TryDequeue([ref]$Record)
				
				if ($Record)
				{
					[PSFramework.Logging.ProviderHost]::LoggingState = 'Writing'
					foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
					{
						if ($___provider.MessageApplies($Record))
						{
							try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.ErrorEvent, $null, $Record) }
							catch { $___provider.Errors.Push($_) }
						}
					}
					
					foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
					{
						if ($___instance.MessageApplies($Record))
						{
							try { $null = & $___instance.ErrorCommand $Record }
							catch { $___instance.AddError($_) }
						}
					}
				}
				[PSFramework.Message.LogHost]::LastLogged = [DateTime]::Now
			}
			#endregion Error Event
			
			#region End Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
			{
				try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.EndEvent, $null, $null) }
				catch { $___provider.Errors.Push($_) }
			}
			foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
			{
				try { $null = & $___instance.EndCommand }
				catch { $___instance.AddError($_) }
			}
			#endregion End Event
			
			#region Finalize / Cleanup
			# Adding $true will cause it to also return disabled providers / instances that are intitialized
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized($true))
			{
				if ($___provider.Enabled) { continue }
				try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.FinalEvent, $null, $null) }
				catch { $___provider.Errors.Push($_) }
				$___provider.Initialized = $false
			}
			foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances($true))
			{
				if ($___instance.Enabled) { continue }
				try { $null = & $___instance.FinalCommand }
				catch { $___instance.AddError($_) }
				$___instance.Initialized = $false
			}
			#endregion Finalize / Cleanup
			
			[PSFramework.Logging.ProviderHost]::LoggingState = 'Ready'
			
			# Skip sleeping if the next messages already await
			if ([PSFramework.Message.LogHost]::OutQueueLog.Count -gt 0) { continue }
			Start-Sleep -Milliseconds ([PSFramework.Message.LogHost]::NextInterval)
		}
	}
	catch
	{
		$wasBroken = $true
	}
	finally
	{
		#region Flush log on exit
		if (([PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName].State -like "Running") -and (-not [PSFramework.Configuration.ConfigurationHost]::Configurations["psframework.logging.disablelogflush"].Value))
		{
			#region Start Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
			{
				try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.StartEvent, $null, $null) }
				catch { $___provider.Errors.Push($_) }
			}
			foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
			{
				try { $null = & $___instance.StartCommand }
				catch { $___instance.AddError($_) }
			}
			#endregion Start Event
			
			#region Message Event
			while ([PSFramework.Message.LogHost]::OutQueueLog.Count -gt 0)
			{
				$Entry = $null
				$null = [PSFramework.Message.LogHost]::OutQueueLog.TryDequeue([ref]$Entry)
				if ($Entry)
				{
					[PSFramework.Logging.ProviderHost]::LoggingState = 'Writing'
					foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
					{
						if ($___provider.MessageApplies($Entry))
						{
							try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.MessageEvent, $null, $Entry) }
							catch { $___provider.Errors.Push($_) }
						}
					}
					
					foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
					{
						if ($___instance.MessageApplies($Entry))
						{
							try { $null = & $___instance.MessageCommand $Entry }
							catch { $___instance.AddError($_) }
						}
					}
				}
			}
			#endregion Message Event
			
			#region Error Event
			while ([PSFramework.Message.LogHost]::OutQueueError.Count -gt 0)
			{
				$Record = $null
				$null = [PSFramework.Message.LogHost]::OutQueueError.TryDequeue([ref]$Record)
				
				if ($Record)
				{
					[PSFramework.Logging.ProviderHost]::LoggingState = 'Writing'
					foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
					{
						if ($___provider.MessageApplies($Record))
						{
							try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.MessageEvent, $null, $Record) }
							catch { $___provider.Errors.Push($_) }
						}
					}
					
					foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
					{
						if ($___instance.MessageApplies($Record))
						{
							try { $null = & $___instance.ErrorCommand $Record }
							catch { $___instance.AddError($_) }
						}
					}
				}
			}
			#endregion Error Event
			
			#region End Event
			foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
			{
				try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.EndEvent, $null, $null) }
				catch { $___provider.Errors.Push($_) }
			}
			foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
			{
				try { $null = & $___instance.EndCommand }
				catch { $___instance.AddError($_) }
			}
			#endregion End Event
		}
		#endregion Flush log on exit
		
		#region Final Event
		foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
		{
			try { $null = $ExecutionContext.InvokeCommand.InvokeScript($false, $___provider.FinalEvent, $null, $null) }
			catch { $___provider.Errors.Push($_) }
		}
		foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
		{
			try { $null = & $___instance.FinalCommand }
			catch { $___instance.AddError($_) }
		}
		
		foreach ($___provider in [PSFramework.Logging.ProviderHost]::GetInitialized())
		{
			$___provider.Initialized = $false
		}
		foreach ($___instance in [PSFramework.Logging.ProviderHost]::GetInitializedInstances())
		{
			$___instance.Initialized = $false
		}
		foreach ($___provider in [PSFramework.Logging.ProviderHost]::Providers.Values)
		{
			if ($___provider.ProviderVersion -eq 'Version_1') { continue }
			
			$___provider.Instances.Clear()
		}
		#endregion Final Event
		
		if ($wasBroken) { [PSFramework.Logging.ProviderHost]::LoggingState = 'Broken' }
		else { [PSFramework.Logging.ProviderHost]::LoggingState = 'Stopped' }
		
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName].SignalStopped()
	}
}

Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'PSFramework.Logging' -NoMessage

$exemptedProcesses = 'CacheBuilder64', 'CacheBuilder', 'ImportModuleHelp'
# Do not start background Runspace if ...
if (
	-not (
		# ... run in the PowerShell Studio Cache Builder
		(($Host.Name -eq 'Default Host') -and ((Get-Process -Id $PID).ProcessName -in $exemptedProcesses)) -or
		# ... run in Azure Functions
		($env:AZUREPS_HOST_ENVIRONMENT -like 'AzureFunctions/*')
	)
)
{
	Start-PSFRunspace -Name 'PSFramework.Logging' -NoMessage
}