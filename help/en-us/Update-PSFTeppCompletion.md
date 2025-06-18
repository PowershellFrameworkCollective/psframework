---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version:
schema: 2.0.0
---

# Update-PSFTeppCompletion

## SYNOPSIS
Imports provided values to parameters configured for an auto-training argument completer.

## SYNTAX

```
Update-PSFTeppCompletion [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
When registering an Argument Completer using "Register-PSFTeppScriptblock", it is possible to configure it for automatic training ("-AutoTraining").
Doing so will not do anything ... by itself.
When you apply the argument completer to a parameter, it is now essential to do so via _attribute_ and not via "Register-PSFTeppArgumentCompleter", as the automatic training depends on the attribute.

Finally, within your command, simply call this Cmdlet - it will automatically match bound parameters against parameter attributes and add all applicable values to the completion cache, allowing the completion to offer the new values henceforth.

For finer control of adding explicit values to a specific completer's offered values, use "Add-PSFTeppCompletion" instead.

## EXAMPLES

### Example 1
```powershell
PS C:\> Update-PSFTeppCompletion
```

Imports provided values to parameters configured for an auto-training argument completer.

## PARAMETERS

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
