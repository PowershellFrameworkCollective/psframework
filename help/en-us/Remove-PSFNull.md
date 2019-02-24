---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version: https://psframework.org/documentation/commands/PSFramework/Remove-PSFNull.html
schema: 2.0.0
---

# Remove-PSFNull

## SYNOPSIS
Filters out null objects.

## SYNTAX

```
Remove-PSFNull [-InputObject <PSObject>] [-AllowEmptyCollections] [-AllowEmptyStrings] [-Enumerate]
 [<CommonParameters>]
```

## DESCRIPTION
This cmdlet can be used to filter out $null objects, empty collections and empty strings from the pipeline.

## EXAMPLES

### Example 1: Sweeping the Pipeline
```
C:\PS> Get-Something | Remove-PSFNull | Do-Something
```

In this example, Remove-PSFNull cleans up the pipeline from null-equivalent objects before passing output along to Do-Something

## PARAMETERS

### -InputObject
The items to filter

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AllowEmptyCollections
By default, empty collections are dropped from the output.
Using this switch, they are passe along.

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

### -AllowEmptyStrings
By default, empty strings are discarded.
Setting this switch causes them to be passed through instead.

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

### -Enumerate
By default, output is not enumerated (Lists are sent along the pipeline as Lists, not individual items).
If Remove-PSFNull should enumerate output after all, set this switch.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Online Documentation:](https://psframework.org/documentation/commands/PSFramework/Remove-PSFNull.html)

