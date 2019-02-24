---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version: https://psframework.org/documentation/commands/PSFramework/Test-PSFShouldProcess.html
schema: 2.0.0
---

# Test-PSFShouldProcess

## SYNOPSIS
Implements the shouldprocess question.

## SYNTAX

### Message (Default)
```
Test-PSFShouldProcess -Target <String> -Action <String> [-PSCmdlet <PSCmdlet>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### String
```
Test-PSFShouldProcess -Target <String> -ActionString <String> [-ActionStringValues <Object[]>]
 [-PSCmdlet <PSCmdlet>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This command can be used in other commands to implement the ShouldProcess question asked if using the command requires confirmation.
This replaces / wraps the traditional ShouldProcess call, makes it easier to read in script and allows mocking it.

## EXAMPLES

### Example 1: Basic Usage
```
if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $item -Action "Performing some arbitrary action") {

}
```

This will test whether the user should be prompted for confirmation, will do so if necessary and report back the results.

## PARAMETERS

### -PSCmdlet
The $PSCmdlet variable of the calling function.
Used to ensure the actual prompt logic as intended is being used.

```yaml
Type: PSCmdlet
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Target
The target that is being processed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Action
The action that will be performed on the target.

```yaml
Type: String
Parameter Sets: Message
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActionString
Localized string of the action that will be performed on the target.
Omit the modulename in the string.
For more details on the PSFramework localization feature, see the help on Import-PSFLocalizedString.

```yaml
Type: String
Parameter Sets: String
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ActionStringValues
Specify values to format into the localization string specified.
For more details on the PSFramework localization feature, see the help on Import-PSFLocalizedString.

```yaml
Type: Object[]
Parameter Sets: String
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Online Documentation](https://psframework.org/documentation/commands/PSFramework/Test-PSFShouldProcess.html)

