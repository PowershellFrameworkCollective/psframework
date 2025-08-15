---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version:
schema: 2.0.0
---

# Assert-PSFInternalCommand

## SYNOPSIS
Verifies, that the command calling it in turn was only called from another command within the same module.

## SYNTAX

```
Assert-PSFInternalCommand -PSCmdlet <PSCmdlet> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Verifies, that the command calling it in turn was only called from another command within the same module.

Modules can have their internal commands accessed directly from outside of their own module.
For example, by loading the psm1 file - or their own ps1 file, if they are shipped separately - it becomes possible, to circumvent the verified interface of the publicly exposed command.
In a secure code management scenario, where validated modules are allowlisted, this might allow attackers
to execute commands flagged as trusted, that should not be exposed directly.

With this command, we can prevent this issue, but potentially make development harder.
It is recommended to place this command only as part of the build step - for example by putting it into the code commented out,
then remove the comment during build, before publishing the module.

## EXAMPLES

### Example 1
```powershell
PS C:\> Assert-PSFInternalCommand -PSCmdlet $PSCmdlet
```

Ensures the current command calling Assert-PSFInternalCommand was only called from another command in the same module.

## PARAMETERS

### -PSCmdlet
The $PSCmdlet variable of the calling command.
This ensures that any exceptions are thrown in the context of the calling command, making this Cmdlet functionally invisible.

```yaml
Type: PSCmdlet
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
