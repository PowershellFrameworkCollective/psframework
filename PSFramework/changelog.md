# CHANGELOG

## X.X.X.X : XXXX-XX-XX
 - New: Parameter Attribute: `[PSFValidateScript]`, allowing validating with scripts that offer easy to read messages.
 - New: Parameter Attribute: `[PSFValidatePattern]`, allowing validating with regex patterns that offer easy to read messages.
 - Upd: Configuration from registry order change: All users (enforced) > Per user (enforced) > Per user (default) > All users (default) (#89)

## 0.9.14.47 : 2018-04-02
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