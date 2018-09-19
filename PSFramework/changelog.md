# CHANGELOG
## 0.10.27.129
 - Upd: Encoding enhanced, now supports UTF8 both with and withlut BOM

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