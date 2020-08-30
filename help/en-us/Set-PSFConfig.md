---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version: https://psframework.org/documentation/commands/PSFramework/Set-PSFConfig.html
schema: 2.0.0
---

# Set-PSFConfig

## SYNOPSIS
Sets configuration entries.

## SYNTAX

### FullName (Default)
```
Set-PSFConfig -FullName <String> [-Value <Object>] [-Description <String>] [-Validation <String>]
 [-Handler <ScriptBlock>] [-Hidden] [-Default] [-Initialize] [-SimpleExport] [-ModuleExport] [-AllowDelete]
 [-DisableValidation] [-DisableHandler] [-PassThru] [-EnableException] [<CommonParameters>]
```

### Persisted
```
Set-PSFConfig -FullName <String> -PersistedValue <String> [-PersistedType <ConfigurationValueType>]
 [-Description <String>] [-Validation <String>] [-Handler <ScriptBlock>] [-Hidden] [-Default] [-Initialize]
 [-SimpleExport] [-ModuleExport] [-AllowDelete] [-DisableValidation] [-DisableHandler] [-PassThru]
 [-EnableException] [<CommonParameters>]
```

### Module
```
Set-PSFConfig [-Module <String>] -Name <String> [-Value <Object>] [-Description <String>]
 [-Validation <String>] [-Handler <ScriptBlock>] [-Hidden] [-Default] [-Initialize] [-SimpleExport]
 [-ModuleExport] [-AllowDelete] [-DisableValidation] [-DisableHandler] [-PassThru] [-EnableException]
 [<CommonParameters>]
```

## DESCRIPTION
This function creates or changes configuration values.
These can be used to provide dynamic configuration information outside the PowerShell variable system.

## EXAMPLES

### Example 1: Simple
```
C:\PS> Set-PSFConfig -FullName 'MyModule.User' -Value "Friedrich"
```

Creates or updates a configuration entry under the module "MyModule" named "User" with the value "Friedrich"

_

### Example 2: Module Definition
```
C:\PS> Set-PSFConfig -Name 'mymodule.User' -Value "Friedrich" -Description "The user under which the show must go on." -Handler $scriptBlock -Initialize -Validation String
```

Creates a configuration entry ...
- Named "mymodule.user"
- With the value "Friedrich"
- It adds a description as noted
- It registers the scriptblock stored in $scriptBlock as handler
- It initializes the script.
This block only executes the first time a it is run like this.
Subsequent calls will be ignored.
- It registers the basic string input type validator
This is the default example for modules using the configuration system.
Note: While the -Handler parameter is optional, it is important to add it at the initial initialize call, if you are planning to add it.
Only then will the system validate previous settings (such as what a user might have placed in his user profile)

_

### Example 3: Hiding things
```
C:\PS> Set-PSFConfig 'Company' 'ConfigLink' 'https://www.example.com/config.xml' -Hidden
```

Creates a configuration entry named "ConfigLink" in the "Company" module with the value 'https://www.example.com/config.xml'.
This entry is hidden from casual discovery using Get-PSFConfig.

_

### Example 4: Default Settings
```
C:\PS> Set-PSFConfig -FullName 'Network.Firewall' -Value '10.0.0.2' -Default
```

Creates a configuration entry named "Firewall" in the "Network" module with the value '10.0.0.2'
This is only set, if the setting does not exist yet.
If it does, this command will apply no changes.

## PARAMETERS

### -FullName
The full name of a configuration element.
Must be namespaced \<Module\>.\<Name\>.
The name can have any number of sub-segments, in order to better group configurations thematically.

```yaml
Type: String
Parameter Sets: FullName, Persisted
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of the configuration entry.
If an entry of exactly this non-casesensitive name already exists, its value will be overwritten.
Duplicate names across different modules are possible and will be treated separately.
If a name contains namespace notation and no module is set, the first namespace element will be used as module instead of name.
Example:
-Name "Nordwind.Server"
Is Equivalent to
-Name "Server" -Module "Nordwind"

```yaml
Type: String
Parameter Sets: Module
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Module
This allows grouping configuration elements into groups based on the module/component they serve.
If this parameter is not set, the configuration element must have a module name in the name parameter (the first segment will be taken, irrespective of whether that makes sense).

```yaml
Type: String
Parameter Sets: Module
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The value to assign to the named configuration element.

```yaml
Type: Object
Parameter Sets: FullName, Module
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Using this, the configuration setting is given a description, making it easier for a user to comprehend, what a specific setting is for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Validation
The name of the validation script used for input validation.
These can be used to validate make sure that input is of the proper data type.
New validation scripts can be registered using Register-PSFConfigValidation

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Handler
A scriptblock that is executed when a value is being set.
Is only executed if the validation was successful (assuming there was a validation, of course)

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Hidden
Setting this parameter hides the configuration from casual discovery.
Configurations with this set will only be returned by Get-Config, if the parameter "-Force" is used.
This should be set for all system settings a user should have no business changing (e.g.
for Infrastructure related settings such as mail server).

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Default
Setting this parameter causes the system to treat this configuration as a default setting.
If the configuration already exists, no changes will be performed.
Useful in scenarios where for some reason it is not practical to automatically set defaults before loading user profiles.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Initialize
Use this when setting configurations as part of module import.
When initializing a configuration, it will only do a thing if the configuration hasn't already been initialized (So if you load the module multiple times or in multiple runspaces, it won't make a difference)
Also, if there already was a non-initialized setting set for a given configuration, it will then try to set the old value again.
This value will be processed by handlers, if any are set.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisableValidation
This parameters disables the input validation - if any - when processing a setting.
Normally this shouldn't be circumvented, but just in case, it can be disabled.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisableHandler
This parameter disables the configuration handlers.
Configuration handlers are designed to automatically process input set to a config value, in addition to writing the value.
In many cases, this is used to improve performance, by forking the value location also to a static C#-field, which is then used, rather than searching a Hashtable.
Normally these shouldn't be circumvented, but just in case, it can be disabled.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableException
Replaces user friendly yellow warnings with bloody red exceptions of doom!
Use this if you want the function to throw terminating errors you want to catch.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersistedValue
In most circumstances an internal parameter.
Applies the serialized value to a setting.
Used for restoring data from configuration files that should only be deserialized when the module consuming it is already imported.

```yaml
Type: String
Parameter Sets: Persisted
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersistedType
In most circumstances an internal parameter.
Paired with PersistedValue, used to specify the data type of the serialized object set in its serialized state.

```yaml
Type: ConfigurationValueType
Parameter Sets: Persisted
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SimpleExport
Enabling this will cause the module to use friendly json notation on export to file.
This may result in loss of data precision, but makes it easier to edit settings in file.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleExport
Using 'Export-PSFConfig -ModuleName \<ModuleName\>' settings flagged with this switch will be exported to a default path if they have been changed from the initial default value.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the changed configuration setting object.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllowDelete
By default, settings that have been once defined are considered unremovable.
Some workflows however require being able to fully dump configuration settings.
Enable this switch to make a configuration setting deletable.

Note:

- Settings that are initialized, can only be declared deletable during initialization. Later attempts to change this, as well as previous settings will be ignored.
- Settings that are defined and enforced by policy cannot be deleted no matter what.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSFramework.Configuration.Config
## NOTES

## RELATED LINKS

[Online Documentation](https://psframework.org/documentation/commands/PSFramework/Set-PSFConfig.html)

