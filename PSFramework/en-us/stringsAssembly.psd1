@{
	# Commands
	'Assembly.Callback.Failed'									   = 'Error when executing callback {0}'
	
	# Computer Management
	'Assembly.ComputerManagement.SessionContainer.NoPSSessionKey'  = 'Session Container for "{0}" does not contain a PSSession connection.'
	'Assembly.ComputerManagement.SessionContainer.NoCimSessionKey' = 'Session Container for "{0}" does not contain a CimSession connection.'
	
	# Configuration
	'Assembly.ConfigurationHost.ConfigNotFound'				       = 'The configuration item {0} could not be found in the configuration system'
	
	# Filter
	'Assembly.Filter.InvalidName'								   = 'Invalid filter name: {0}. Make sure the name specified only consists of numbers, letters and underscores (and equals neither 0 or 1)!'
	'Assembly.Filter.ConditionSet.Required'					       = 'No Condition Set provided! Either permanently assign a set to the expression or specify it as a parameter!'
	'Assembly.Filter.NoCondition'								   = 'Cannot evaluate a filter expression without any conditions!'
	'Assembly.Filter.Condition.NotInSet'						   = 'The condition {0} cannot be found in the provided condition set {1}. Conditions included in that set: {2}'
	'Assembly.Filter.Expression.SyntaxError'					   = 'Error parsing expression! {0}'
	
	# Utility
	'Assembly.Size.ComparisonError'							       = 'Cannot compare a {0} to a {1}'
	
	'Assembly.UtilityHost.AliasNotFound'						   = 'Failed to find alias: {0}'
	'Assembly.UtilityHost.AliasProtected'						   = 'The alias "{0}" is protected and cannot be removed!'
	'Assembly.UtilityHost.AliasReadOnly'						   = 'The alias "{0}" is read only! To remove it, also specify the "-Force" parameter.'
	
	'Assembly.UtilityHost.PrivateFieldNotFound'				       = 'Could not find a private field named "{0}"'
	'Assembly.UtilityHost.PrivatePropertyNotFound'				   = 'Could not find a private property named "{0}"'
	'Assembly.UtilityHost.PrivateMethodNotFound'				   = 'Could not find a private method named "{0}"'
	
	# Validation
	'Assembly.Validation.Generic.ArgumentIsEmpty'				   = 'Could not validate input, no data was provided!'
	'Assembly.Validation.UntrustedData'						       = 'This data has been flagged as untrustworthy: {0}!'
	'Assembly.Validation.LanguageMode.NotAScriptBlock'			   = 'The specified input was not detected as a scriptblock: {0}. Can only validate scriptblocks!'
	'Assembly.Validation.LanguageMode.BadMode'					   = 'The specified script is in language mode {1} when only {0} is allowed.'
	'Assembly.Validation.ScriptBlock.IsNull'					   = 'No validation scriptblock found!'
}