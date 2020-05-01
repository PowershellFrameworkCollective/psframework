$exceptions = @{ }

<#
A list of entries that MAY be in the language files, without causing the tests to fail.
This is commonly used in modules that generate localized messages straight from C#.
Specify the full key as it is written in the language files, do not prepend the modulename,
as you would have to in C# code.

Example:
$exceptions['LegalSurplus'] = @(
    'Exception.Streams.FailedCreate'
    'Exception.Streams.FailedDispose'
)
#>
$exceptions['LegalSurplus'] = @(
	'Assembly.Callback.Failed'
	'Assembly.ComputerManagement.SessionContainer.NoCimSessionKey'
	'Assembly.ComputerManagement.SessionContainer.NoPSSessionKey'
	'Assembly.ConfigurationHost.ConfigNotFound'
	'Assembly.UtilityHost.AliasNotFound'
	'Assembly.UtilityHost.AliasProtected'
	'Assembly.UtilityHost.AliasReadOnly'
	'Assembly.UtilityHost.PrivateFieldNotFound'
	'Assembly.UtilityHost.PrivateMethodNotFound'
	'Assembly.UtilityHost.PrivatePropertyNotFound'
	'Assembly.Validation.UntrustedData'
	'Configuration.Remove-PSFConfig.ShouldRemove'
	'Configuration_ValidateLanguage'
	'FlowControl.Invoke-PSFProtectedCommand.Confirmed'
	'FlowControl.Invoke-PSFProtectedCommand.Denied'
	'FlowControl.Invoke-PSFProtectedCommand.Failed'
	'FlowControl.Invoke-PSFProtectedCommand.Retry'
	'FlowControl.Invoke-PSFProtectedCommand.Success'
)

$exceptions