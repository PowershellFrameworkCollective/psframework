---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version:
schema: 2.0.0
---

# ConvertTo-PSFHashtable

## SYNOPSIS
Converts an object into a hashtable.

## SYNTAX

```
ConvertTo-PSFHashtable [-Include <String[]>] [-Exclude <String[]>] [-IncludeEmpty] [-Inherit]
 [-InputObject <PSObject[]>] [<CommonParameters>]
```

## DESCRIPTION
Converts an object into a hashtable.

- Use -Exclude to selectively blacklist properties / keys
- Use -Include to selectively whitelist properties / keys
- Use -Inherit to inherit values from variables when missing keys explicitly included in -Include

Optimized to selectively convert $PSBoundParameters for passing through parameters to internal command calls.

## EXAMPLES

### BEISPIEL 1
```
Get-ChildItem | ConvertTo-PSFHashtable
```

Scans all items in the current path and converts those objects into hashtables.

### BEISPIEL 2
```
$parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential, Target -Inherit
```

Clones the bound parameters into a new hashtable that can now be used for splatting-
Only parameters explicitly specified or with default values will be included.

## PARAMETERS

### -Exclude
The propertynames to exclude.
Must be full property-names, no wildcard/regex matching.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Include
The propertynames to include.
Must be full property-names, no wildcard/regex matching.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeEmpty
By default, only properties on the input object are included.
In order to force all properties defiend in -Include to be included, specify this switch.
Keys added through this have an empty ($null) value.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inherit
By default, only properties on the input object are included.
With this parameter, missing keys are substituted for by looking in the caller scope for variables with the same name.
This is explictly designed to allow inheriting default parameter values when cloning $PSBoundParameters.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
The object(s) to convert

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Collections.Hashtable
## NOTES

## RELATED LINKS
