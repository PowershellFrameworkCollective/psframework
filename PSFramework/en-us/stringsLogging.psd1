@{
	'Import-PSFLoggingProvider.Import.Error'			   = "Error loading json data from {0}" # $effectivePath
	'Import-PSFLoggingProvider.Datum.Error'			       = "Error processing logging provider entry" # 
	
	'Install-PSFLoggingProvider.Provider.NotFound'		   = "Provider {0} not found!" # $Name
	'Install-PSFLoggingProvider.Installation.Error'	       = "Failed to install provider '{0}'" # $Name
	
	'Register-PSFLoggingProvider.RegistrationEvent.Failed' = "Failed to register logging provider '{0}' - Registration event failed." # $Name
	'Register-PSFLoggingProvider.Installation.Failed'	   = "Failed to install logging provider '{0}'" # $Name
	'Register-PSFLoggingProvider.NotInstalled.Termination' = "Failed to enable logging provider {0} on registration! It was not recognized as installed. Consider running 'Install-PSFLoggingProvider' to properly install the prerequisites." # $Name
	
	'Set-PSFLoggingProvider.Provider.NotFound'			   = 'Provider {0} not found!' # $Name
	'Set-PSFLoggingProvider.Provider.V1NoInstance'		   = 'The Provider {0} is a first generation logging provider and does not support instances!' # $Name
	'Set-PSFLoggingProvider.Provider.NotInstalled'		   = 'Provider {0} not installed! Run "Install-PSFLoggingProvider" first' # $Name
}