# List of functions that should be ignored
$global:FunctionHelpTestExceptions = @(
    'Get-PSFScriptblock'
)

<#
  List of arrayed enumerations. These need to be treated differently. Add full name.
  Example:

  "Sqlcollaborative.Dbatools.Connection.ManagementConnectionType[]"
#>
$global:HelpTestEnumeratedArrays = @(
	'PSFramework.License.ProductType[]'
	'PSFramework.Message.MessageLevel[]'
	'System.Management.Automation.PSLanguageMode[]'
	'PSLanguageMode[]'
)

<#
  Some types on parameters just fail their validation no matter what.
  For those it becomes possible to skip them, by adding them to this hashtable.
  Add by following this convention: <command name> = @(<list of parameter names>)
  Example:

  "Get-DbaCmObject"       = @("DoNotUse")
#>
$global:HelpTestSkipParameterType = @{
    
}
