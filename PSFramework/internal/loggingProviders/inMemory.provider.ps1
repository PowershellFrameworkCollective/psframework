$begin_event = {
	$name = $script:Instance.Name
	if (-not $name) { $name = 'Default' }
	if ([PSFramework.Message.LogHost]::InMemoryLogs[$name]) { $script:logger = [PSFramework.Message.LogHost]::InMemoryLogs[$name] }
	else { $script:logger = [PSFramework.Logging.MemoryLog]::new($name) }

	$settings = Select-PSFConfig -FullName "$($script:Instance.InstanceCfgRoot).*" | Where-Object _FullName -EQ $script:Instance.InstanceCfgRoot

	if ($null -ne $settings.MaxCount) { $script:logger.MaxCount = $settings.MaxCount }
	if ($null -ne $settings.MaxAge) { $script:logger.MaxAge = $settings.MaxAge -as [PsfTimeSpan] }
	if ($settings.ShouldArchive) { $script:logger.ShouldArchive = $true }
	if ($settings.ArchivePath) {
		$script:logger.ArchivePath = [PSFNewFile]$settings.ArchivePath
	}

	if ($settings.RunspaceBound -and $script:logger.RetireWithRunspace -eq [guid]::Empty) {
		# At the end so it shows up in Get-PSFLoggingError, but still configures the rest of the logging.
		throw "The RunspaceBound setting only works when defined through 'Set-PSFLoggingProvider'"
	}
}
$message_event = {
	param (
		$Message
	)
	
	$script:logger.Add($Message)
}

$end_event = {
	if ($script:logger.RetireWithRunspace -eq [guid]::Empty) { return }

	$runspace = Get-Runspace -InstanceId $script:logger.RetireWithRunspace
	if ($runspace) { return }

	$disableName = "LoggingProvider.InMemory.Enabled"
	if ($script:Instance.Name -and $script:Instance.Name -ne 'Default') { $disableName = "LoggingProvider.InMemory.$($script:Instance.Name).Enabled" }
	Set-PSFConfig -FullName $disableName -Value $false
}

$final_event = {
	$script:logger.Retire()
}

$configurationScript = {
	param ($BoundParameters)

	if ($BoundParameters.RunspaceBound) {
		$effectiveInstanceName = $BoundParameters.InstanceName
		if (-not $effectiveInstanceName) { $effectiveInstanceName = 'Default'}

		# Prepare Runspace Expiration Content
		if ([PSFramework.Message.LogHost]::InMemoryLogs[$effectiveInstanceName]) {
			$logger = [PSFramework.Message.LogHost]::InMemoryLogs[$effectiveInstanceName]
		}
		else { $logger = [PSFramework.Logging.MemoryLog]::new($effectiveInstanceName) }
		$logger.RetireWithRunspace = [runspace]::DefaultRunspace.InstanceId
		$null = $BoundParameters.Remove('RunspaceBound')

		# Add the current runspace to the runspace filter
		$runspaces = @([runspace]::DefaultRunspace.InstanceId) + $BoundParameters.IncludeRunspaces | Remove-PSFNull
		$BoundParameters['IncludeRunspaces'] = @($runspaces)
	}
}

$configuration_Settings = {
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.InMemory.MaxCount' -Value $null -Initialize -Validation long -Description 'Maximum number of messages in this log before retiring the oldest entries when adding.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.InMemory.MaxAge' -Value $null -Initialize -Validation timespan -Description 'Maximum age entries may remain in the log. Entries beyond that limit will be removed as new entries are added.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.InMemory.ShouldArchive' -Value $false -Initialize -Validation bool -Description 'Whether the inmemory log should remain available after closing the log within memory. If $false, Get-PSFMessage can only access the data until the logging provider is disabled.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.InMemory.ArchivePath' -Value $null -Initialize -Validation string -Description 'When disabling the logging provider, write the data to this fully-valid file path. The folder must exist, relative paths may not be resolved as expected.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.InMemory.RunspaceBound' -Value $false -Initialize -Validation bool -Description 'If set to true, this logging provider will filter for messages of the runspace calling Set-PSFLoggingProvider and automatically disable & archive when the runspace no longer exists. Note: Will error out if not defined via Set-PSFLoggingProvider. Runspaces may be recycled when used via RunspacePools.'
}
$paramRegisterPSFLoggingProvider = @{
	Name                       = 'inmemory'
	Description                = 'Writes messages to an in-memory list accessible through Get-PSFMessage.'
	Version2                   = $true
	ConfigurationRoot          = 'PSFramework.Logging.InMemory'
	InstanceProperties         = 'MaxCount', 'MaxAge', 'ShouldArchive', 'ArchivePath', 'RunspaceBound'
	MessageEvent               = $message_Event
	ConfigurationSettings      = $configuration_Settings
	ConfigurationDefaultValues = @{
		RunspaceBound = $false
		ShouldArchive = $false
	}
}

# Register the Console logging provider
Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider -BeginEvent $begin_event -EndEvent $end_event -FinalEvent $final_event -ConfigurationScript $configurationScript