$start_event = {

}
$message_event = {
	param (
		$Message
	)
	
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
	Description                = 'Writes messages to an inmemory list accessible through Get-PSFMessage.'
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
Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider