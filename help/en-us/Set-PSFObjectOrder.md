---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version: https://go.microsoft.com/fwlink/?LinkID=2097038
schema: 2.0.0
---

# Set-PSFObjectOrder

## SYNOPSIS
Wrapper around Sort-Object, unifying the parameter seruface between PS5 and PS7.

## SYNTAX

### Default (Default)
```
Set-PSFObjectOrder [-Stable] [-Descending] [-Unique] [-InputObject <PSObject>] [[-Property] <SortParameter[]>]
 [-Culture <String>] [-CaseSensitive] [<CommonParameters>]
```

### Top
```
Set-PSFObjectOrder [-Descending] [-Unique] -Top <Int32> [-InputObject <PSObject>]
 [[-Property] <SortParameter[]>] [-Culture <String>] [-CaseSensitive] [<CommonParameters>]
```

### Bottom
```
Set-PSFObjectOrder [-Descending] [-Unique] -Bottom <Int32> [-InputObject <PSObject>]
 [[-Property] <SortParameter[]>] [-Culture <String>] [-CaseSensitive] [<CommonParameters>]
```

## DESCRIPTION
Wrapper around Sort-Object, unifying the parameter seruface between PS5 and PS7.

## EXAMPLES

### Example 1
```powershell
PS C:\> 1,4,2,3 | Set-PSFObjectOrder
```

Sorts the numbers in an ascending order.

## PARAMETERS

### -Bottom
Gets or sets the number of items to return in a Bottom N sort.

```yaml
Type: Int32
Parameter Sets: Bottom
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CaseSensitive
Indicates that the sort is case-sensitive. By default, sorts aren't case-sensitive.

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

### -Culture
Specifies the cultural configuration to use for sorts. Use `Get-Culture` to display the system's culture configuration.

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

### -Descending
Indicates that `Set-PSFObjectOrder` sorts the objects in descending order. The default is ascending order.

To sort multiple properties with different sort orders, use a hash table. For example, with a hash table you can
sort one property in ascending order and another property in descending order.

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

### -InputObject
To sort objects, send them down the pipeline to `Set-PSFObjectOrder`. If you use the InputObject parameter to submit a collection of items, `Set-PSFObjectOrder` receives one object that represents the collection. Because one object can't be sorted, `Set-PSFObjectOrder` returns the entire collection unchanged.

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

### -Property
The Properties that would be used for Sorting.
Accepts the default input `Sort-Object` would have expected, but also supports prefixes to determine sort order:

- ">Name": Sorts by Name (Descending)
- "<Name": Sorts by Name (Ascending)

It can also handle direct references to sub-properties or methods:

- "Timestamp.Year": Sorts by only the year property of the timestamp.

```yaml
Type: SortParameter[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Stable
The sorted objects are delivered in the order they were received when the sort criteria are equal.

```yaml
Type: SwitchParameter
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Top
Specifies the number of objects to get from the start of a sorted object array. This results in a stable sort.

```yaml
Type: Int32
Parameter Sets: Top
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Unique
Indicates that `Set-PSFObjectOrder` eliminates duplicates and returns only the unique members of the collection. The first instance of a unique value is included in the sorted output. Unique is case-insensitive. Strings that only differ by character case are considered the same. For example, character and CHARACTER.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

[https://go.microsoft.com/fwlink/?LinkID=2097038](https://go.microsoft.com/fwlink/?LinkID=2097038)

