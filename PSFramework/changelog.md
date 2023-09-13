# CHANGELOG

## 1.9.310 (2023-09-11)

- Fix: Register-PSFConfig - fails to register piped configuration settings
- Fix: Parameter Class: PsfLiteralPath - fails to error on invalid paths

## 1.9.308 (2023-09-07)

- New: Parameter Class: PsfPath - Interprets and resolves input as file or folder paths
- New: Parameter Class: PsfPathLex - Interprets and resolves input as file or folder paths, throws no errors
- New: Parameter Class: PsfNewFile - Resolves the input into the path to a file, so long as at least its parent folder exists
- New: Parameter Class: PsfFile - Interprets and resolves input as file paths
- New: Parameter Class: PsfFileLax - Interprets and resolves input as file paths, throws no errors
- New: Parameter Class: PsfDirectory - Interprets and resolves input as directory paths
- New: Parameter Class: PsfDirectoryLax - Interprets and resolves input as directory paths, throws no errors
- New: Parameter Class: PsfLiteralPath - Resolves input as a path without wildcards
- New: Parameter Class: PsfLiteralPathLax - Resolves input as a path without wildcards, throws no errors
- New: Register-PSFArgumentTransformationScriptblock - Registers an input conversion scriptblock for use in Parameter Binding.
- New: Argument Transform: PsfScriptTransformation - Provide script-based custom argument transformation logic
- New: Get-PSFLoggingError - Retrieve errors that happened when trying to log messages.
- Upd: Get-PSFConfig - added `-Persisted` parameter to search for settings that have been persisted, rather than their current value in process.
- Upd: Unregister-PSFConfig - added support for the new persisted config object type returned by Get-PSFConfig.
- Upd: Register-PSFConfig - added support to register to environment variables, affecting child processes only.
- Upd: Invoke-PSFProtectedCommand - added parameter `-RetryWaitEscalation` to allow increased wait times each retry that fails
- Fix: Register-PSFConfig - specifying both file _and_ registry scopes would have it ignore file scopes

## 1.8.291 (2023-07-11)

- Fix: ConvertTo-PSFHashTable - the `-Remap` parameter always acts as an `-Include` parameter, causing the command to always disregard additional properties not specified. (#587)
- Fix: Write-PSFMessage - the `-NoNewLine` parameter causes the error `Write-PSFMessage: A parameter cannot be found that matches parameter name 'NoNewLage'.` (#586)

## 1.8.289 (2023-06-13)

- New: Resolve-PSFItem - Resolves paths provided.
- New: Register-PSFMessageColorTransform - Adds a rule that changes the color of messages when applicable.
- New: Unregister-PSFMessageColorTransform - Removes a previously registered message color rule.
- New: Get-PSFMessageColorTransform - Lists registered message color rules.
- Upd: ConvertTo-PSFHashtable - Automatically adds all keys of a `-Remap` hashtable to include
- Upd: ConvertTo-PSFHashtable - Allows using `-Include` and `-Exclude` together with `-ReferenceCommand`
- Upd: ConvertTo-PSFHashtable - When explicitly binding the `CaseSensitive` parameter, input objects that are hashtables will be converted to the proper case handling
- Upd: ConvertTo-PSFHashtable - Added `-ReferenceParameterSetName` parameter to only include parameters applicable to a specified parameterset
- Upd: Messages - added option to include the level of a message in the message written to screen
- Upd: Import-PSFPowerShellDataFile - now accepts path as a positional argument
- Upd: Import-PSFPowerShellDataFile - now also supports jsonc documents
- Upd: Type PSFCmdlet - minor performance improvement (removed dynamic scriptblocks for message events)
- Upd: Type PsfScriptBlock - added second constructor (Scriptblock, bool) to unwrap nested scriptblocks (e.g. when importing from psd1)
- Upd: Logging Provider: logfile - added ability to rename properties and access sub-properties (such as entries in the data field)
- Upd: Logging Provider: logfile - added new supported header: DataCompact. This will include a compacted form of the header data.
- Upd: Logging Provider: eventlog - added ability to specify event id via data field 'EventLog.ID'
- Upd: Logging Provider: eventlog - added option to use the first purely numeric tag as eventid
- Upd: Logging Provider: eventlog - added option to provide a hashtable to map tags to eventid
- Fix: Disable-PSFLoggingProvider - throws an error about timeout being reached while still disabling correctly.

## 1.7.270 (2023-02-06)

- Upd: Import-PSFPowerShellDataFile - added parameter `Psd1Mode`, enabling psd1 files with multiple hashtables to be loaded without exposing yourself to executing unsafe code.
- Fix: Tab Completion - fails to process hashtables for enriched Tab Completion

## 1.7.268 (2023-02-06)

- New: Type PsfErrorRecord - a custom error record type to provide better and easier error records.
- Upd: Tab Completion - added support for ListItemText property on results
- Upd: Stop-PSFFunction - `-AlwaysWarning` will be respected when explicitly bound to false.
- Upd: Stop-PSFFunction - added `-Level` parameter to support customizing the level of the log message.
- Upd: Type Callstack - added methods to select a subset and customize the string representation.
- Upd: ConvertTo-PSFClixml - improved performance when processing a large number of objects.
- Upd: Various minor performance improvements
- Upd: Logging Provider: GELF - supports specifying the repository to use when installing the required module
- Upd: Logging Provider: SQL - supports specifying the repository to use when installing the required module
- Upd: build logic - Added option to compile PSFramework.dll as part of the included build logic
- Fix: Set-PSFLoggingProvider - losing messages though using `-Wait` parameter
- Fix: Logging Provider: AzureLogAnalytics - headers are not respected
- Fix: Logging Provider: SQL - does not includes `Line` by default (thanks @ashdar ; #564)
- Fix: Logging Provider: SQL - stops trying to create table to log to if it already exists
- Fix: Logging Provider: SQL - prevented SQL Injection via Table Name or Schema Name
- Fix: Logging Provider: logfile - does not flush messages in time during scheduled task
- Fix: Get-PSFDynamicContentObject - retrieving more than one DCO at a time fails
- Fix: Stop-PSFFunction - prevented CLM escape through exception or target transformation.
- Fix: Get-PSFPath - fails to resolve temp path when imported into a JEA endpoint
- Fix: Tab Completion - fails to complete in StrictMode

## 1.7.249 (2022-10-17)

- New: Command Disable-PSFConsoleInterrupt - Prevents the use of CTRL+C from interrupting the console.
- New: Command Enable-PSFConsoleInterrupt - Re-enables the use of CTRL+C to interrupt the console.

## 1.7.247 (2022-10-13)

- Fix: Logging Provider: sql - does not respect the schema when creating a new table

## 1.7.246 (2022-10-06)

- Fix: Logging Provider: sql - occasional error during logging due to connection pool running out of capacity (#546)

## 1.7.245 (2022-10-05)

- Fix: Logging Provider: sql - fails to log (#546)

## 1.7.244 (2022-09-20)

- New: Configuration `PSFramework.Message.Style.NoColor` - Disables color output of messages on screen, for compatibility with custom hosts that do not implement NoNewLine on host messages.
- Upd: Command: Set-PSFLoggingProvider - Added `-ExcludeError` parameter to also support excluding error-level messages
- Fix: Logging Provider: logfile - Critical bug preventing CSV logging in some common situations
- Fix: Logging Provider: logfile - Encoding would not be applied correctly
- Fix: Logging Provider: logfile - Changing the path of an enabled logging provider fails
- Fix: Logging Provider: logfile - When writing CSV, resuming writing to an existing logfile would add the headers again
- Fix: Write-PSFMessage - The `Prefix` configuration settings were not respected when writing messages to the console

## 1.7.237 (2022-06-15)

- Upd: Tab Expansion - now supports custom tooltips for completion results by returning hashtables with a `Text` and a `ToolTip` key
- Upd: Command: Invoke-PSFProtectedCommand - updated the `-ErrorEvent` script to receive one argument - the error of what went wrong.

## 1.7.235 (2022-06-04)

- New: Command: Clear-PSFMessage - Clears the in-memory log of the message system.
- New: Configuration Setting: PSFramework.Runspace.RunspaceBoundValue.CleanupInterval - The interval at which Runspace-Bound Variables will be cleaned up, deleting values associated with expired runspaces.
- Upd: Type: UtilityHost - added public static method: InvokePrivateStaticMethod
- Upd: Command: Join-PSFPath - added alias `ChildPath` to parameter `Path` (#525)
- Upd: Command: Set-PSFLoggingProvider - added `-Wait` parameter to have the ommand wait until the provider is fully initialized
- Upd: Logging Provider: logfile - improved performance (x5) and prevented other processes from blocking write access to file
- Fix: Logging Provider: logfile - Type Json would ignore the `JsonString` setting
- Fix: Memory leak that would affect long-running processes that utilize runspaces (#523; @adamdriscoll)

## 1.7.227 (2022-05-13)

- Fix: Memory leak that would affect long-running processes that utilize runspaces (extended)

## 1.7.226 (2022-05-13)

- New: Component: Temp Item - simplifies creation and lifecycle management of temporary items - files, folders, ...
- New: Configuration Validation: Secret - accepts either a PSCredential, a SecureString or a string, stores the secret as a PSCredential (#508)
- New: ScriptBlock: PSFramework.Validate.SafeName - ensures input only consists of letters, numbers, dots, underscores and dashes
- Upd: Command: Import-PSFPowerShellDataFile - added support for json files
- Upd: Command: Import-PSFPowerShellDataFile - added `-Unsafe` parameter to allow loading psd1 files with multiple hashtables
- Upd: Logging Provider: Azure Log Analytics - added TimeFormat option to define, just how exactly timestamps are being logged
- Upd: Logging Provider: Azure Log Analytics - added Headers option to define, which properties (in which order) are being logged (#507)
- Upd: Logging Provider: Azure Log Analytics - WorkspaceID & SharedKey now updated to use the secret validation, supporting SecureString or Credential objects in addition to plaintext string (#508)
- Upd: Type: UtilityHost - added public static method: GetPrivateStaticField
- Upd: Type: UtilityHost - added public static method: GetCallerInfo to get information on whoever called your command
- Upd: Removal-Event has been hidden from Get-Job
- Fix: Memory leak that would affect long-running processes that utilize runspaces

## 1.6.214 (2021-11-11)

- New: Command: New-PSFThrottle - Create a throttle object, used to not exceed a certain rate of executions per time interval.
- Upd: ConvertTo-PSFHashtable - add `-Remap` parameter, allowing the user to rename keys in the return hashtable
- Upd: ConvertTo-PSFHashtable - add `-ReferenceCommand` parameter, automatically populating `Include` with parameters on the specified command
- Upd: Invoke-PSFProtectedCommand - added `-Level` parameter to control, at which level messages are being generated
- Upd: Invoke-PSFProtectedCommand - added `-ErrorEvent` parameter, allowing to include conditional logic if the protected command fails
- Upd: Logging Provider: SQL - added "Schema" option, allowing to pick the database schema to write to
- Fix: Module cannot be used in PSv5.0
- Fix: Select-PSFObject cannot be used in a JEA endpoint
- Fix: Logging Runspace slowly leaks memory

## 1.6.205 (2021-06-16)

- Upd: Get-PSFUserChoice - new parameter `-Vertical` which will present options in a vertical, numbered list instead.
- Fix: Module cannot be used in PSv4 or older
- Fix: Join-PSFPath - fails to normalize path separators correctly on some OS (#488)
- Fix: Concurrent access to runspace-bound variables is now threadsafe and will no longer risk state corruption.

## 1.6.201 (2021-05-06)

- Fix: Set-PSFFeature - removed input validation due to runtime issue.
- Fix: Stop-PSFFunction - exception without message if using strings.
- Fix: Detection when running in a JEA endpoint.

## 1.6.198 (2021-04-12)

- Fix: Import-PSFLocalizedString - removed language validation that would lead to import-time issues in pipeline scenarios.

## 1.6.197 (2021-04-07)

- Fix: Validation Scripts - FileSystem validations fail incorrectly on hidden paths (#476)
- Fix: ConfigurationSchema metaJson - Relative Path detection broken (#475)

## 1.6.195 (2021-04-01)

- Fix: PsfValidateScript - unhandled error if test fails without scriptblock generating an exception
- Fix: New-PSFFilter - hang & error if not providing any Filter Condition Set information

## 1.6.193 (2021-04-01)

- New: Command Set-PSFObjectOrder - sort objects with custom properties processing
- New: Validation Attribute PsfValidatePSVersion - ensures parameters are only used in the correct version
- Upd: Command Get-PSFFilterCondition - added parameter `-SetName` to allow searching for filter conditions assigned to a specific Condition Set.
- Upd: Command New-PSFTeppCompletionResult - is now a public command
- Upd: LoggingProvider logfile - added options `MoveOnFinal` and `CopyOnFinal` that allow shipping the finalized logs to a destinaiton path.
- Upd: Type FilterContainer - added `Add()` method, enabling submitting pre-created conditions and condition sets
- Upd: ConfigurationSchema metaJson - Added support for weblinks to configuration files
- Upd: ConfigurationSchema metaJson - Added support for direct json string input
- Upd: ConfigurationSchema metaJson - Added support for psd1 files
- Upd: PSFCmdlet - Added method TestFeature(), integrating the feature component into the class.
- Fix: Tab Completion for Filter Condition Set names completes condition names.
- Fix: PsfValidateScript - Errors are now handled gracefully and can be surfaced to the user by using "{2}" in the error message.

## 1.6.181 (2021-03-17)

- New: Component: Filter - adds the ability to define userfriendly, safe filter expression syntaxes
- Upd: Command Set-PSFScriptblock - added ability to specify tags & description to scriptblocks (@nyanhp ; #457)
- Upd: Command Set-PSFScriptblock - added parameter "-Local" to enable runspace-local scriptblock definition.
- Upd: Command Get-PSFScriptblock - added ability to search by tags & description (@nyanhp ; #457)
- Upd: Type ScriptBlockItem - added invocation methods for rich scriptblock-invocation
- Upd: ConfigurationSchema metaJson - added Tree & DynamicTree nodes for more userfriendly authoring
- Upd: Module layout - updated build process to improve import speed somewhat
- Fix: Command Set-PSFScriptblock - fails to set global to false on existing scriptblock
- Fix: LoggingProvider logfile - fails to add a new line in json files when specifying the -JsonNoComma option.

## 1.5.172 : 2021-02-09

- Fix: Write-PSFMessageProxy - fails with "Cannot overwrite variable" when writing to host

## 1.5.171 : 2021-02-07

- Upd: LoggingProvider azureloganalytics - added Tags & Data properties to uploaded data

## 1.5.170 : 2021-01-17

- Fix: LoggingProvider console - error initializing configuration
- Fix: LoggingProvider console - fails to properly insert the file into the message

## 1.5.168 : 2021-01-17

- New: Command Add-PSFLoggingProviderRunspace : Adds a runspace to the list of included runspaces on a logging provider instance
- New: Command Remove-PSFLoggingProviderRunspace : Removes a runspace from the list of included runspaces on a logging provider instance
- New: Configuration Validation: guidarray - ensures only legal guids can be added
- New: LoggingProvider: console - enables logging to the console screen
- New: Class PSFramework.Utility.PsfException - adds localization capability to exceptions
- Upd: Logging - Added ability to filter by runspace id
- Upd: Logging - Added level "Error", functionally identical to warning
- Upd: LoggingProvider: eventlog - Messages with the new level "Error" will trigger an error event
- Upd: LoggingProvider: logfile - Added new setting: MutexName - allows handling file access conflict if writing from multiple processes
- Upd: LoggingProvider: logfile - Added new settings: JsonCompress, JsonString and JsonNoComma to better allow just how json logfiles are being created
- Upd: LoggingProvider: splunk - Added new settings: Index, Source and SourceType
- Upd: Set-PSFLoggingProvider - Added `-IncludeRunspaces` and `-ExcludeRunspaces` parameters
- Upd: Set-PSFLoggingProvider - Added `-RequiresInclude` parameter, excluding all messages that match not at least one include rule.
- Upd: Configuration Validation: bool - now accepts a switch parameter type as input
- Upd: Import-PSFConfig - Add `-EnvironmentPrefix` and `-Simple` parameters, allowing import of configuration from environment variables.
- Upd: Configuration - Automatically imports configuration from environment variables on module import.
- Upd: UtilityHost.cs - Added a static property `FriendlyCallstack` returning the current script callstack as a snapshot.
- Fix: LoggingProvider: sql - Fails to write to database due to hardcoded db name on insert (#444)

## 1.4.150 : 2020-09-25

- Fix: Invoke-PSFCallback ignores modulename filter.

## 1.4.149 : 2020-09-02

- Upd: New build tools, to increase convenience when importing into/building from internal source code repositories
- Fix: Set-PSFLoggingProvider - default instances are not created
- Fix: Validation Scriptblock: PSFramework.Validate.FSPath - validates correctly

## 1.4.146 : 2020-08-30

- Major: Redesigned the entire logging system to support multi-instance providers and reduce complexity of building custom logging providers.
- New: Added Tab Expansion Plus Plus code to provide extended tab completion on PS3-4
- New: Argument Transformation Attribute: PsfDynamicTransform - allows dynamic object conversion from PSObject, hashtable, or type from a different library version
- New: Feature PSFramework.Stop-PSFFunction.ShowWarning - Causes calls to Stop-PSFFunction to always show warnings. By default, using "-EnableException $true" will only throw the exception but not show the warning.
- New: Command Get-PSFLoggingProviderInstance : Lists current logging provider instances
- New: Command Export-PSFModuleClass : Publishes a PowerShell class to be available from outside of the module it is defined in.
- New: Command Select-PSFConfig : Select a subset of configuration entries and return them as objects.
- New: Command Test-PSFLanguageMode : Tests, in what language mode a specified scriptblock is in.
- New: Command Import-PSFLoggingProvider : Imports additional logging providers or logging provider configuration from a filesystem path or network url.
- New: Parameter Attribute PsfArgumentCompleter : Extends ArgumentCompleter and replaces the _need_ for Register-PSFArgumentCompleter.
- New: Validation Attribute PsfValidateLanguageMode : Validates the language mode of a scriptblock.
- New: Logging Provider: eventlog - logs to the windows eventlog
- New: Logging Provider: splunk - logs to a splunk SIEM server
- New: Logging Provider: azureloganalytics - logs to Azure Log Analytics
- New: Validation Scriptblock: PSFramework.Validate.FSPath - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.FSPath.File - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.FSPath.FileOrParent - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.FSPath.Folder - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.Path - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.Path.Container - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.Path.Leaf - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.Uri.Absolute - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.Uri.Absolute.File - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.Uri.Absolute.Https - prebuilt validation scriptblocks for use with PsfValidateScript. Validation messages available with same label.
- New: Validation Scriptblock: PSFramework.Validate.TimeSpan.Positive - prebuilt validation scriptblock for use with PsfValidateScript. Validation messages available with same label.
- New: Configuration Validation: uriabsolute - Ensures the input is an absolute Uri.
- New: Configuration Validation: integer1to9 - Ensures the input is an integer between 1 and 9.
- New: Configuration Setting: PSFramework.Logging.Enabled - allows fully disabling the logging runspace by configuration.
- New: Class PsfScriptBlock - Wraps a scriptblock and provides native support for $_, $this, $args as input. Also supports rehoming your scriptblock to a runspace or the global scope withoutbreaking languagemode.
- New: Class RunspaceBoundValueGeneric - Allows statically maintaining values that may contain specific values per runspace.
- New: Class PSFNumber - Wraps a number into a humanized format while retaining its nature as number
- Upd: Invoke-PSFProtectedCommand - Added `-RetryCondition` parameter to allow custom scriptblocks for retry validation
- Upd: ConvertTo-PSFHashtable - Added `-CaseSensitive` parameter
- Upd: Write-PSFMessage - Support for including level-based prefixes for CI/CD services such as Azure DevOps. (thanks, @splaxi)
- Upd: Write-PSFMessage - New parameter: `-NoNewLine` avoids adding a new line after writing to screen.
- Upd: Write-PSFMessage - New parameter: `-PSCmdlet` will in combination with `-EnableException` and `-ErrorRecord` write the errors in the context of the specified $PSCmdlet.
- Upd: Write-PSFMessage - New parameter: `-Data` allows specifying additional data points for the log
- Upd: Test-PSFPowerShell - now able to execute remotely, testing a target host.
- Upd: New-PSFSupportPackage - added linux & mac support (thanks, @nyanhp)
- Upd: New-PSFSupportPackage - now supports taking console buffer screenshot from ISE
- Upd: Register-PSFLoggingProvider - require FullLanguage language mode on all scriptblock parameters.
- Upd: Register-PSFLoggingProvider - added parameters to allow creation of second generation logging providers.
- Upd: PSFCmdlet - WriteMessage() now also accepts a Hashtable input as Data
- Upd: PSFCmdlet - WriteLocalizedMessage() now also accepts a Hashtable input as Data
- Upd: Logging - Increased log execution interval and added idle detection with extended intervals in non-use to reduce CPU impact.
- Upd: Logging - Disabled autostart of logging runpace in PowerShell Studio Module cacher
- Upd: Logging - Disabled autostart of logging runpace in Azure Functions
- Upd: Logging Provider: logfile - Updated to generation 2 to enable multi-instance capabilities.
- Upd: Logging Provider: logfile - Added new output format: CMTrace
- Upd: Get-PSFConfig - Now accepts from the pipeline
- Upd: Get-PSFConfigValue - Now accepts positional input
- Upd: Set-PSFConfig - Now accepts from the pipeline
- Upd: Set-PSFConfig - Handler scriptblocks can now use $_ instead of $args[0]
- Upd: Unregister-PSFConfig - Added failover on non-windows from UserDefault to FileUserLocal scope
- Upd: Unregister-PSFConfig - Added failover on non-windows from SystemDefault to FileSystem scope
- Upd: Disable-PSFTaskEngineTask - Added Name parameter
- Upd: Enable-PSFTaskEngineTask - Added Name parameter
- Upd: Added debug mode for more visual PSFramework import
- Upd: Added scheduled timer to clean up runspace bound values for runspaces that no longer exist
- Upd: Register-PSFTeppScriptblock - added `-Global` parameter
- Upd: Set-PSFScriptblock - added `-Global` parameter
- Upd: Validation Attribute PsfValidateScript - added `Global = ` named property to execute script in the global context
- Upd: Register-PSFLoggingProvider - flagged as unsafe for JEA
- Upd: Set-PSFTypeAlias - now accepts from the pipeline
- Upd: Stop-PSFFunction - added parameter `-AlwaysWarning`, ensuring it will always show the warning, even when throwing a terminating exception.
- Upd: Logging Provider logfile - added configuration for encoding
- Upd: Logging Provider logfile - added configuration for UTC timestamps
- Upd: Logging Provider logfile - added logrotate capability
- Upd: Logging Provider GELF - converted to v2 provider, enabling multiple instances
- Upd: Configuration Validation timespan - now supports PSFTimespan notation
- Upd: Invoke-PSFProtectedCommand now respects explicitly bound `-WhatIf` and `-Confirm` parameters.
- Upd: Logging Component - Disabled wait time in logging cycle if messages pending, to avoid delays during message floods
- Fix: Register-PSFLoggingProvider - respects `InstallationOptional` setting
- Fix: Install-PSFLoggingProvider - now correctly passes installation parameters as hashtable into the installation scriptblock
- Fix: Set-PSFLoggingProvider - now correctly passes installation parameters as hashtable into the configuration scriptblock
- Fix: ConvertTo-PSFHashtable : The `-Include` parameter functionality was case sensitive (as the sole parameter being so)
- Fix: Missing help for new cmdlets has been fixed and integrated into CI/CD
- Fix: PSFCmdlet - fails with 'Variable was precompiled for performance reasons' in some situations when writing messages.
- Fix: Localization - logging language only honored when specifying string values.
- Fix: Register-PSFLoggingProvider - auto-install fails to notify system of success, failing the registration auto-enable even when it installed correctly.
- Fix: Set-PSFConfig - security fix
- Fix: Set-PSFConfig - security fix
- Fix: Import-PSFConfig - resolved scriptblock handling issues in multi-runspace scenarios
- Fix: Register-PSFConfig - error detecting parameterset in pipeline scenarios
- Fix: Register-PSFConfig - failed to failover for SystemDefault scope on non-Windows
- Fix: Logging Component - Logging Provider Instances would ignore updating filters at runtime
- Fix: Logging Component - Execute proper cleanup when provider / instance get disabled explicitly

## 1.1.59 : 2019-11-02

- New: Command Get-PSFPath : Returns configured paths.
- New: Command Set-PSFPath : Configures a path under a specified name.
- New: Command Compare-PSFArray : Compares two arrays with each other.
- New: Command Get-PSFCallback : Returns registered callback scripts.
- New: Command Invoke-PSFCallback : Executes registered callback scripts.
- New: Command Register-PSFCallback : Registers a callback script.
- New: Command Unregister-PSFCallback : Removes a registered callback script.
- New: ATA : TypeTransformationAttribute - transforms input into the target type using powershell type coercion. Use to override language primitive overrides, especially to allow binding switch parameters to bool parameters of commands defined in C#
- Upd: Invoke-PSFProtectedCommand - now accepts switch parameters on -EnableException
- Upd: Invoke-PSFProtectedCommand - now accepts ContinueLabel parameter
- Upd: Invoke-PSFProtectedCommand - now explicitly confirms successful execution
- Upd: Invoke-PSFProtectedCommand - now supports retry attempts, using `-RetryCount`, `-RetryWait` and `-RetryErrorType` parameters
- Upd: Export-PSFClixml - add `-PassThru` parameter
- Upd: Get-PSFTaskEngineCache - collector can no longer be executed in parallel
- Upd: Logging Provider: logfile - now supports custom time formats in the logfiles
- Upd: Logging Provider: filesystem - now supports custom time formats in the logfiles
- Upd: PSFCmdlet - new Invoke() overload supporting scriptblocks as string input
- Upd: PSFCmdlet - new StopCommand() method to integrate into flowcontrol
- Upd: PSFCmdlet - new StopLocalizedCommand() method to integrate into flowcontrol
- Upd: PSFCmdlet - new GetCaller() overload supporting going up a specified number of steps the callstack
- Upd: PSFCmdlet - new GetCallerInfo() method to obtain optimized/parsed caller information
- Upd: PSFCmdlet - new InvokeCallback() method to integrate cmdlets into the callback component
- Fix: Get-PSFTaskEngineCache - collector script no longer bound by runspace affinity.
- Fix: Import - concurrency issue, parameterclass mappings used to be subject to concurrent access issues.

## 1.0.35 : 2019-08-26

- Upd: Removed runspace affinity of invoked scriptblocks of taskengine, rather than recreating them
- Fix: Tab Completion scriptblocks are again aware of $fakeBoundParameter and other automatic variables

## 1.0.33 : 2019-08-11

- Fix: Build order update fixes unknown attribute error

## 1.0.32 : 2019-08-11

- New: Validation Attribute: PsfValidateTrustedData - equivalent to ValidateTrustedData, but exists on PS3+ (no effect before 5+)
- New: Command Import-PSFPowerShellDataFile - wraps around Import-PowerShellDataFile and makes it available on PSv3+
- Upd: Parameter Class: Computer : Add support for output of Get-ADDomainController
- Upd: ConvertTo-PSFHashtable : Reimplemented as Cmdlet for better performance
- Upd: ConvertTo-PSFHashtable : Adding -Inherit parameter, causing the command to pick up missing includes from variables.
- Upd: Select-PSFObject : Parameter `-Property` now validates for trusted data
- Upd: Tab Completion: PSFramework-Input-ObjectProperty - will now properly unroll arrays to provide completion for the first value in one.
- Upd: Register-PSFTeppScriptblock : Changed some internal behavior
- Fix: Write-PSFMessage fails with error on localized string when specifying an error record
- Fix: Write-PSFMessage fails with error when specifying $null for format values
- Fix: Remove-PSFConfig fails to log deleted configuration name
- Fix: Register-PSFTaskEngineTask fails to reset correctly
- Fix: PsfValidateSet fails unexpectedly under certain circumstances

## 1.0.19 : 2019-05-21

- Upd: Import-PSFConfig adding -PassThru parameter.
- Upd: Write-PSFMessageProxy adding parameters to better support all common redirection scenarios.
- Upd: FileSystem Logging Provider now supports option to serialize target objects
- Fix: New-PSFSupportPackage no longer tries to export pssnappins on PowerShell Core
- Fix: Importing PSFramework within a JEA Endpoint throws exceptions
- Fix: Closed Memory Leak in Serialization component

## 1.0.12 : 2019-03-20

- Fix: TaskEngineCache would throw null exception on any access.

## 1.0.11 : 2019-03-20

- New: Convenience type: `[PSFSize]` will display size numbers in a human friendly way without losing mathematical precision or usefulness as number.
- Upd: Write-PSFMessage : `-StringValues` parameter has now an alias called `-Format` and can be used together with `-Message` parameter.
- Upd: Get-PSFTaskEngineCache : Interna rework to utilize expiration of cached data and automatic data refresh.
- Upd: Set-PSFTaskEngineCache : Added `-Lifetime`, `-Collector` and `-CollectorArgument` parameters to facilitate cache expiration and automatic data refresh.
- Upd: Test-PSFTaskEngineCache : Interna rework.
- Upd: Task Engine : Including state information, estimated next execution time and last error.
- Upd: Test-PSFParameterBinding now supports the `-Mode` parameter, allowing to differentiate between explicitly bound parameters or scriptblocks that will be bound by pipeline input.
- Upd: PSFCmdlet class for PSFramework implementing Cmdlets now offers a `WriteLocalizedMessage()` method to utilize the localization feature when writing messages.
- Fix: Write-PSFMessage would not localize correctly

## 1.0.2 : 2019-03-11

- Upd: ConvertTo-PSFHashtable now supports `-Include` & `-IncludeEmpty` parameter
- Fix: Broken dynamic parameters for logging providers (#287)

## 1.0.0 : 2019-02-24

Fundamental Change: The configuration system is now extensible in how it processes input.
This unlocks fully supported custom configuration layouts, stored in any preferred notation, hosted by any preferred platform.

Component added: Feature Management
Enables declaring feature flags that can be set both globally as well as controlled or overridden on a per-module basis.

- New: Command Register-PSFConfigSchema extends the type of input understood as configuration data.
- New: Command Remove-PSFConfig allows to remove configuration items from memory that have been flagged as deletable.
- New: Command Select-PSFPropertyValue selects the value of properties based on various conditions.
- New: Command Register-PSFSessionObjectType registers session objects for use in Session Containers.
- New: Command New-PSFSessionContainer creates a multi-session object in order to easily be able to pass through sessions to a single computer with multiple protocols.
- New: Command ConvertFrom-PSFArray flattens object properties for export to csv or other destinations that cannot handle tiered data.
- New: Command Invoke-PSFProtectedCommand combines should process testing, error handling, messages & logging and flow control into one, neat package.
- New: Command Get-PSFFeature lists registered features that can be enabled or disabled.
- New: Command Set-PSFFeature enables or disables features supporting this component.
- New: Command Test-PSFFeature resolves the enablement status of a feature.
- New: Command Register-PSFFeature registers a feature within the feature component.
- New: Optional Feature: PSFramework.InheritEnableException allows inheriting the EnableException variable by commands offering that parameter. This feature is only available on a per-module basis.
- New: Configuration Schema: 'default'. Old version configuration schema for Import-PSFConfig.
- New: Configuration Schema: 'MetaJson'. Capable of ingesting complex json files, evaluating and expanding environment variables and loading include files.
- Upd: Configuration: Removed enforced lowercasing of configuration entries. Configuration as published before had not been case-sensitive, the new version is still not case sensitive.
- Upd: ConvertTo-PSFHashTable now correctly operates against all dictionaries, including `$PSBoundParameters`
- Upd: Invoke-PSFCommand will reuse the PSSession in a Session Container.
- Upd: Import-PSFConfig now has a `-AllowDelete` parameter, enabling the later deletion of imported configuration settings.
- Upd: Test-PSFShouldProcess now no longer requires specifying the `-PSCmdlet` parameter.
- Upd: Test-PSFShouldProcess now supports localized strings integration.
- Upd: Set-PSFConfig now has a `-AllowDelete` parameter, enabling the later deletion of a configuration setting.
- Upd: Import-PSFConfig now has a `-Schema` parameter, allowing to switch between configuration schemata.
- Upd: Major push to avoid import static resource conflict when importing in many runspaces in parallel
- Upd: Wait-PSFMessage will no longer cause lengthy delays when waiting for the logs to flush - now it _knows_ when it's over, rather than guessing with a margin.
- Fix: Write-PSFMessage strings: Unknown keys will no longer cause an empty message on screen, instead display the missing key.
- Fix: Configuration - DefaultValue would be overwritten each time a configuration item's `Initialize` property is set (rather than only on the first time it is set to true)
- Fix: Logs flushing would not reliably trigger in all circumstances

## 0.10.31.179 : 2019-02-07

- Fix: Broken application of module / tag filters on logging providers (#272)
- Fix: Write-PSFMessage parameter `-String` would also require a `-StringValues` to be specified
- Fix: Import-PSFLocalizedString removed validation on parameter `-Language` due to issues when executing during any module import.
- Fix: Culled logging at the end of a process

## 0.10.31.176 : 2019-01-13

- New: Configuration validation: Credential. Validates PSCredential objects.
- New: The most awesome Tab Completion for input properties _ever_ .
- Upd: Write-PSFMessage supports localized strings through the `-String` and `-StringValues` parameters
- Upd: Stop-PSFFunction supports localized strings through the `-String` and `-StringValues` parameters
- Upd: Test-PSFShouldProcess now supports ShouldProcess itself. This should help silence tests on commands reyling on it.
- Upd: Message component supports localized strings
- Upd: Logging component logs in separate language than localized messages to screen / userinteraction
- Upd: Logging - filesystem provider now has a configuration to enable better output information: `psframework.logging.filesystem.modernlog`
- Upd: Import-PSFLocalizedString now accepts wildcard path patterns that resovle to multiple files.
- Upd: Adding tab completion for `Register-PSFTeppArgumentCompleter`
- fix: Missing localization strings - Fix: Missing tab completion for modules that register localized strings

## 0.10.30.165 : 2018-12-01

- New: Command Join-PSFPath performs multi-segment path joins and path normalization
- New: Command Remove-PSFAlias deletes global aliases
- New: Configuration setting to define current language
- Upd: PsfValidatePattern now supports localized strings using the `ErrorString` property.
- Fix: Race condition / concurrent access on license content during import with ramping up CPU availability

## 0.10.29.160 : 2018-11-04

- New: Command ConvertTo-PSFHashtable converts objects into hashtables
- New: Command Get-PSFPipeline grants access to the current pipeline and all its works.
- New: Command Get-PSFScriptblock retrieves scriptblocks from a static dictionary
- New: Command Set-PSFScriptblock stores scriptblocks in a static dictionary
- New: Command Get-PSFLocalizedString retrieves localied versions of strings
- New: Command Import-PSFLocalizedString imports localized strings into the strings store
- New: Logging Provider for gelf / graylog
- Upd: PsfValidateScript can now consume stored scriptblocks
- Upd: PsfValidateScript will now understand both $_ and $args[0]
- Upd: PsfValidateSet now supports localized strings using the `ErrorString` property.
- Upd: PsfValidateScript now supports localized strings using the `ErrorString` property.
- Upd: Logging runspace now loads the same copy of PSFramework that spawned it (#238)
- Fix: PsfValidateSet fails on completion scriptblock with whitespace value
- Fix: Get-PSFConfig will show bad value in default table. Correct data still stored (#243)

## 0.10.28.144 : 2018-10-28

- Upd: Module Architecture update
- Upd: Linked online help for commands (by Andrew Pla)
- Upd: Configuration - redirected SystemDefault to FileSystem scope on non-Windows systems (#229)
- Upd: Message/Logging - Error records are now directly associated with their respective message and available as the ErrorRecord property (#230)
- Fix: Reset-PSFConfig fails with error (#223)
- Fix: Configuration: Registering empty string will register the wrong value (#224)
- Fix: Module on UNC Path Fails to Load (#227)
- Fix: Get-PSFUserChoice handling single options more gracefully (#228)
- Other: Add formal policy on supported platforms and breaking change policy

## 0.10.27.135 : 2018-10-12

- Fix: New dynamic content collections' Reset() method doesn't do a thing.

## 0.10.27.134 : 2018-10-12

- New: Command Get-PSFUserChoice allows prompting the user for a choice
- New: Configuration Validator: integerarray
- Upd: Encoding enhanced, now supports UTF8 both with and without BOM
- Upd: Improved Dynamic Content Objects for concurrent collections
- Fix: Resolve-PSFPath will fail to resolve "." properly (#209)
- Fix: Configuration error storing collection values in combination with setting a handler, ending up with nested arrays.

## 0.10.27.128 : 2018-09-14

- New: Command Wait-PSFMessage waits for logs to be flushed, also offers option to terminate logging runspaces.
- New: Command ConvertFrom-PSFClixml converts data that was serialized from objects back _into_ that object
- New: Command ConvertTo-PSFClixml converts objects into clixml data (binary or string, compressed or not)
- New: Parameter class: EncodingParameter
- Upd: Register-PSFTaskEngineTask `-Interval` and `-Delay` parameters changed to PSFTimeSpan for greater user convenience
- Upd: Stop-PSFFunction add `-StepsUpward` parameter, enabling upscope interrupt signals
- Other: Redesigned module layout and build procedure to compile the module into few files, improving import speed

## 0.9.25.113 : 2018-09-05

- Fix: Stop-PSFFunction throws null method (#188)

## 0.9.25.112 : 2018-09-04

- Upd: Select-PSFObject: Supports adding alias properties
- Upd: Select-PSFObject: Supports adding script property properties
- Upd: Select-PSFObject: Supports adding script method properties
- Fix: Stop-PSFFunction fails when called during class constructor (#184)
- Fix: Stop-PSFFunction fails to interrupt when enabling exceptions but not specifying `-Cmdlet` (#185)

## 0.9.25.107 : 2018-08-18

- Upd: Select-PSFObject: Rewritten as Cmdlet in C#, in order to better access variables in calling scopes and for better performance.
- Upd: New-PSFSupportPackage: Add support to selectively pick what gets exported
- Upd: New-PSFSupportPackage: Add configuration that allows organizations to add information on how to submit support packages.
- Upd: Set-PSFDynamicContentObject: Add parameters to pre-seed the object with threadsafe collections, such as queues, lists or dictionaries.
- Fix: Write-PSFMessage will now contain the actual callstack at the time of the writing, rather than when called.
- Fix: Tab Completion Scriptblocks returning un-enumerated arrays would concatenate their results on result caching
- Fix: New-PSFSupportPackage will not export errors
- Fix: Write-HostColor unintentionally adds an extra line between each line.
- Fix: Select-PSFObject: Erroneously adds module name to the typename when specifying a TypeName from a call within a module.

## 0.9.24.98 : 2018-08-14

- New: Reset-PSFConfig: Resets configuration items to their intialized value.
- Upd: Add more comprehensive tests to the configuration system
- Upd: Add tab completion to various commands
- Fix: Logging Provider will not properly change settings on configuration change
- Fix: Import-PSFConfig incorrectly does not support deferred deserialization
- Fix: Unregister-PSFConfig fails to operate when specifying `-Module` and `-Name` parameters to remvoe registry values
- Fix: Logging runspace stops when alternative runspace with PSFramework ends

## 0.9.24.91 : 2018-08-08

- Upd: Export-PSFConfig: Configuration setting set for simple export are no longer marked with a style property, as it is no longer needed and was not simple enough.
- Upd: Configuration: Made the `Style` property on json configuration files optional for simple style export files.
- Fix: Register-PSFConfig export of multiple configuration items would only export a single one
- Fix: Unregister-PSFConfig silently does nothing when selecting a file scope to unregister
- Fix: Write-PSFMessage overwrites variable $string on host level messages (#164)
- Fix: Import-PSFConfig will not accept relative filesystem paths

## 0.9.24.85 : 2018-07-31

- New: Add command Resolve-PSFPath, providing a handy way to resolve input paths in a safe manner.
- New: Add command Export-PSFClixml, providing clixml export by compressing
- New: Add command Import-PSFClixml, providing clixml import, both compressed and uncompressed

## 0.9.23.82 : 2018-07-25

- New: Add command Select-PSFObject, adding the ability to powerfully select stuff.
- Upd: Stop-PSFFunction now has a `-Cmdlet` parameter, allowing to write exceptions in the calling function's scope.

## 0.9.23.80 : 2018-07-23

- Fix: Invoke-PSFCommand errors are not handled properly
- Fix: Write-PSFMessage broke PowerShell v3 compatibility
- Fix: Write-PSFMessage parameter `-Once` would not display correctly on host levels (#156)

## 0.9.23.77 : 2018-07-10

- Fix: Write-PSFMessage errors on repeated use of `-Once`

## 0.9.23.76 : 2018-07-09

- New: PsfValidateSet attribute to handle dynamic validate sets, ties into tab completion system
- New: Add command Set-PSFTeppResult, allows refreshing tje tab completion cache
- Upd: Register-PSFTeppScriptblock now supports result caching with timeout
- Upd: Some documentation updates
- Upd: Write-PSFMessage now allows empty strings or null values
- Fix: Failed to handle persisted empty arrays
- Fix: Failed import in some Linux distributions due to .NET issue in Register-PSFParameterClassMapping & ComputerParameter

## 0.9.22.70 : 2018-06-22

- Upd: Import-PSFConfig now supports weblinks to raw config files or accepts input as raw json string.
- Fix: Export-PSFConfig will not export any module cache settings.

## 0.9.22.68 : 2018-06-20

- New: logfile logging provider, enables dedicated logging to a single file.
- Upd: Logging providers now have dedicated error stacks to help with debugging
- Fix: Automatic configuration import will now properly set policy/enforce state.
- Fix: Set-PSFloggingProvider now updates logging provider configuration settings.
- Fix: Invoke-PSFCommand fails with an enumeration changed exception when cleaning up sessions
- Fix: Set-PSFConfig fixed validation of collections

## 0.9.21.62 : 2018-06-12

- Fix: Invoke-PSFCommand fails with an enumeration changed exception when cleaning up sessions

## 0.9.21.61 : 2018-06-09

- New: Add command Resolve-PSFDefaultParameterValue, allows inheriting targeted default parameter values from the global scope.
- New: Add command Invoke-PSFCommand, allows invoking commands with convenient parameterization and automatic integrated session management.
- Fix: Test-PSFPowerShell rename parameter `-PSEdition` to `-Edition` due to PS6 conflict
- Fix: Export-PSFConfig fails to accept from pipeline (#134)
- Fix: Export-PSFConfig ignores `-SkipUnchanged` parameter (#135)

## 0.9.19.55 : 2018-05-27

- New: Add command Remove-PSFNull, will clean the pipeline from unwanted empty objects.
- New: Add command Test-PSFShouldProcess, implementing the `-Confirm` and `-WhatIf` parameters for a command. Useful to mock the test and make it more readable.
- New: Add command Test-PSFPowerShell, allowing simple powershell environment validation and mocking.

## 0.9.18.52 : 2018-05-20

- New: Add command Import-PSFCmdlet, will register a cmdlet in PowerShell
- New: Add automatic config import from Json files
- New: Add selective per module config import from json
- New: Add simple json export support for improved readability in file
- Upd: Export-PSFConfig - Added feature to export all marked module settings to dedicated export paths
- Upd: Import-PSFConfig - Added feature to import from dedicated config paths by modulename
- Upd: Configuration - Hardened configuration properties enforced by policy against manual changes.
- Upd: Rewrote Set-PSFConfig as cmdlet for performance reasons
- Upd: Added config persistence support for Hashtable
- Upd: Added config persistence support for PSObjects of any kind
- Upd: New-PSFLicense - Added `-Description` and `-Parent` parameters to support inner licenses that are used within another product.
- Upd: Write-PSFMessage - Disabled entering debugging breakpoints on debug stream messages when specifying the `-Debug` parameter.
- Upd: Write-PSFMessage - Added `-Breakpoint` parameter to enter a debugging breakpoint at this location when specifying the `-Debug` parameter.
- Upd: Messages: Added option `'PSFramework.Message.Style.Breadcrumbs'`, enabling display of the full command call-tree, rather than just the calling function's name in displayed messages
- Upd: Messages: Added option `'PSFramework.Message.Style.Functionname'`, enabling users to remove the function name from displayed messages.
- Upd: Messages: Added option `'PSFramework.Message.Style.Timestamp'`, enabling users to remove the timestamp from displayed messages.
- Upd: Messages: Messages written to debug will also include line number if displayed on screen.
- Upd: Messages: The in-memory message log now includes the full callstack and the username.

## 0.9.16.44 : 2018-04-22

- Upd: Add tab completion to Export-PSFConfig.
- Upd: Import-PSFConfig: Added parameter `-Peek` to allow previewing data.
- Upd: Import-PSFConfig: Added parameter `-IncludeFilter` and `-ExcludeFilter` to allow filtering on import

## 0.9.16.43 : 2018-04-22

- New: Add command Export-PSFConfig, will export configuration items to json.
- New: Add command Import-PSFConfig, will import configuration items from json.
- Upd: Parameter class `[PSFDateTime]` will now accept integer as seconds relative to now

## 0.9.15.41 : 2018-04-14

- New: Parameter Attribute: `[PSFValidateScript]`, allowing validating with scripts that offer easy to read messages.
- New: Parameter Attribute: `[PSFValidatePattern]`, allowing validating with regex patterns that offer easy to read messages.
- Upd: Configuration from registry order change: All users (enforced) > Per user (enforced) > Per user (default) > All users (default) (#89)
- Fix: Write-PSFMessage will now properly trigger when called from outside the module with `-Verbose` set
- Fix: Write-PSFMessage will now properly display color-coded messages in system streams (#91)
- Fix: Terminating process using exit would hang until Managed Runspace Timeout (#94)

## 0.9.14.37 : 2018-04-02

- New: Parameter class `[PSFTimeSpan]` allows easy input interpretation of timespan information.
- New: Parameter class `[PSFDateTime]` allows easy input interpretation of datetime information.

## 0.9.13.35 : 2018-03-31

- Fix: Register-PSFConfig would fail with unknown parameter `-Depth`

## 0.9.13.34 : 2018-03-30

- New: Add command Write-PSFMessageProxy (#81)
- New: Add command Set-PSFTypeAlias (#71)
- Upd: Rewrite of `Write-PSFMessage` as cmdlet to significantly improve performance
- Upd: Removing the module or closing the process will now stop all registered runspaces. This is designed to avoid hanging resources.
- Upd: Configuration: Added `Unchanged` property, in order to allow detection of settings that weren't changed by the user. (#79)
- Upd: Slight performance improvements on `Stop-PSFFunction`
- Fix: Fixed critical concept error in Stop-PSFFunction, causing invalid termination in flowcontrol using commands. (#80)

## 0.9.11.25 : 2018-03-11

- Upd: Ensured PS6 non-Windows capability, making registry calls conditional. Configuration cannot be persisted on non-windows for now
- Fix: Fixed critical scope error in Stop-PSFFunction, causing invalid termination in flowcontrol using commands.
- Fix: Fixed tab completion for configuration commands

## 0.9.10.23 : 2018-02-21

- New: Add command Unregister-PSFConfig (#59)
- New: Add command New-PSFSupportPackage (#60)
- Upd: Write-PSFHostColor - new parameters `-NoNewLine` (In line with the same Write-Host parameter) and `-Level` (Allow suppressing messages depending on info message configuration) (#61)
- Upd: Get-PSFTypeSerializationData - new parameter `-Fragment` allows skipping outer XML shell to add to existing type extension XML. Also cleaned up output. (#53)
- Upd: Some internal housekeeping that should have no effect outside the module
- Fix: Set-PSFConfig - Validation of array input would remove all but the first value (#54)

## 0.9.9.20 : 2018-02-18

- Fix: Failed to restore empty array configurations from registry
- Fix: Restored single-value arrays from registry as non-array

## 0.9.9.19 : 2018-01-27

- Upd: Enhanced ComputerParameter parameter class: Supports PSSession and CimSession objects, new property `Type` is available to detect live session objects in order to facilitate reuse. (#46)
- Fix: Tab Expansion commands parameterization and help have been updated to reflect real use requirements (#14)
- Fix: Register-PSFTeppArgumentCompleter used to throw exception on PS3/4, interrupting module import in strict mode (#45)

## 0.9.8.17 : 2018-01-19

- Fix: Fixed bad configuration setting 'PSFramework.Serialization.WorkingDirectory'

## 0.9.8.16 : 2018-01-19

- New: Added command Register-PSFParameterClassMapping
- New: Added command Get-PSFTypeSerializationData
- New: Added command Register-PSFTypeSerializationData
- New: Added class `[PSFramework.Serialization.SerializationTypeConverter]`, a type serializer that can be used to serialize and deserialize types.
- Upd: Messages now also include the file and line they were written in

## 0.9.7.14 : 2018-01-17

- New: Added tests to module
- New: Added parameter class: ComputerParameter (`[PSFComputer]`)
- Upd: Stop-PSFRunspace - Upgraded error handling
- Fix: Get-PSFMessageLevelModifier throw error when output was piped at Remove-PSFMessageLevelModifier
- Fix: Message logging was completely broken

## 0.9.6.12 : 2018-01-12

- Fix: Start-PSFRunspace fails on PS3/4 [#22](https://github.com/PowershellFrameworkCollective/psframework/issues/22)
