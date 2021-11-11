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
	'Assembly.Filter.Condition.NotInSet'
	'Assembly.Filter.ConditionSet.Required'
	'Assembly.Filter.Expression.SyntaxError'
	'Assembly.Filter.InvalidName'
	'Assembly.Filter.NoCondition'
	'Assembly.Size.ComparisonError'
	'Assembly.UtilityHost.AliasNotFound'
	'Assembly.UtilityHost.AliasProtected'
	'Assembly.UtilityHost.AliasReadOnly'
	'Assembly.UtilityHost.PrivateFieldNotFound'
	'Assembly.UtilityHost.PrivateMethodNotFound'
	'Assembly.UtilityHost.PrivatePropertyNotFound'
	'Assembly.Validation.Generic.ArgumentIsEmpty'
	'Assembly.Validation.LanguageMode.BadMode'
	'Assembly.Validation.LanguageMode.NotAScriptBlock'
	'Assembly.Validation.PSVersion.TooLow'
	'Assembly.Validation.ScriptBlock.IsNull'
	'Assembly.Validation.UntrustedData'
	'Clear-PSFResultCache.Clear'
	'Configuration_ValidateLanguage'
	'Configuration.Remove-PSFConfig.ShouldRemove'
	'PSFramework.Configuration.Remove-PSFConfig.ShouldRemove'
	'FlowControl.Invoke-PSFProtectedCommand.Confirmed'
	'FlowControl.Invoke-PSFProtectedCommand.Denied'
	'FlowControl.Invoke-PSFProtectedCommand.Failed'
	'FlowControl.Invoke-PSFProtectedCommand.Retry'
	'FlowControl.Invoke-PSFProtectedCommand.Success'
	'FlowControl.Invoke-PSFProtectedCommand.ErrorEvent'
	'FlowControl.Invoke-PSFProtectedCommand.ErrorEvent.Failed'
	'FlowControl.Invoke-PSFProtectedCommand.ErrorEvent.Success'
	'Reset-PSFConfig.Resetting'
	'Set-PSFTeppResult.UpdateValue'
	'Validate.FSPath'
	'Validate.FSPath.File'
	'Validate.FSPath.Folder'
	'Validate.Path'
	'Validate.Path.Container'
	'Validate.Path.Leaf'
	'Validate.Uri.Absolute.File'
	'Validate.Uri.Absolute.Https'
)

$exceptions