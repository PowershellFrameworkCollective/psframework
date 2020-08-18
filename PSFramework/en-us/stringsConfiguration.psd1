@{
	Configuration_ValidateLanguage					      = '{0} is not recognized as a legal language code, such as "en-US" or "de-DE"'
	
	# Remove-PSFConfig
	'Configuration.Remove-PSFConfig.ShouldRemove'		  = 'Removing configuration item from memory'
	'Configuration.Remove-PSFConfig.InvalidConfiguration' = 'The configuration setting "{0}" could not be found!'
	'Configuration.Remove-PSFConfig.DeleteSuccessful'	  = 'Successfully remove configuration setting: {0}'
	'Configuration.Remove-PSFConfig.DeleteFailed'		  = 'Failed to remove configuration setting: {0} | Can be deleted: {1} | Enforced by policy {2}'
	
	# Schema: default
	'Configuration.Schema.Default.ImportFailed'		      = 'Failed to import {0}' # $Resource
	'Configuration.Schema.Default.SetFailed'			  = "Failed to set '{0}'" # $element.FullName
	
	# Schema: metajson
	'Configuration.Schema.MetaJson.ProcessResource'	      = 'Processing resource: {0}'
	'Configuration.Schema.MetaJson.ProcessFile'		      = 'Reading Node: {0}'
	'Configuration.Schema.MetaJson.ResolveFile'		      = 'Cannot resolve path: {0}'
	'Configuration.Schema.MetaJson.InvalidJson'		      = 'Failed to access json content from: {0}'
	'Configuration.Schema.MetaJson.UnknownVersion'	      = 'Unknown version "{1}" in: {0}'
	'Configuration.Schema.MetaJson.NestedError'		      = 'An error happened when importing config file {0}'
	
	'Export-PSFConfig.ToRegistry'						  = "Cannot export modulecache to registry! Please pick a file scope for your export destination" # 
	'Export-PSFConfig.Write.Error'					      = "Failed to export to file" #
	
	'Get-PSFConfigValue.NoValue'						  = "No Configuration Value available for {0}" # $FullName
	
	'Register-PSFConfig.NoRegistry'					      = "Cannot register configurations on non-windows machines to registry. Please specify a file-based scope" # 
	'Register-PSFConfig.Type.NotSupported'			      = "Invalid Input, cannot export {0}, type not supported" # $Config.FullName
	'Register-PSFConfig.Registering'					  = "Registering {0} for {1}" # $Config.FullName, $Scope
	'Register-PSFConfig.Registering.Failed'			      = "Failed to export {0}, to scope {1}" # $Config.FullName, $Scope
	
	'Reset-PSFConfig.Resetting'						      = 'Reset to default value' # 
	'Reset-PSFConfig.Resetting.Failed'				      = "Failed to reset the configuration item." # 
	
	'Unregister-PSFConfig.NoRegistry'					      = 'Cannot unregister configurations from registry on non-windows machines.' # 
}