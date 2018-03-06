# CHANGELOG

## X.X.X.X : XXXX-XX-XX
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