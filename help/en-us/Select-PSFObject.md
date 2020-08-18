---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version: https://psframework.org/documentation/commands/PSFramework/Select-PSFObject.html
schema: 2.0.0
---

# Select-PSFObject

## SYNOPSIS
Wrapper around Select-Object, extends property parameter.

## SYNTAX

### DefaultParameter (Default)
```
Select-PSFObject [-InputObject <PSObject>] [-Property <SelectParameter[]>] [-ExcludeProperty <String[]>]
 [-ExpandProperty <String>] [-Alias <SelectAliasParameter[]>]
 [-ScriptProperty <SelectScriptPropertyParameter[]>] [-ScriptMethod <SelectScriptMethodParameter[]>] [-Unique]
 [-Last <Int32>] [-First <Int32>] [-Skip <Int32>] [-Wait] [-ShowProperty <String[]>]
 [-ShowExcludeProperty <String[]>] [-TypeName <String>] [-KeepInputObject] [<CommonParameters>]
```

### SkipLastParameter
```
Select-PSFObject [-InputObject <PSObject>] [-Property <SelectParameter[]>] [-ExcludeProperty <String[]>]
 [-ExpandProperty <String>] [-Alias <SelectAliasParameter[]>]
 [-ScriptProperty <SelectScriptPropertyParameter[]>] [-ScriptMethod <SelectScriptMethodParameter[]>] [-Unique]
 [-SkipLast <Int32>] [-ShowProperty <String[]>] [-ShowExcludeProperty <String[]>] [-TypeName <String>]
 [-KeepInputObject] [<CommonParameters>]
```

### IndexParameter
```
Select-PSFObject [-InputObject <PSObject>] [-Unique] [-Wait] [-Index <Int32[]>] [-ShowProperty <String[]>]
 [-ShowExcludeProperty <String[]>] [-TypeName <String>] [-KeepInputObject] [<CommonParameters>]
```

## DESCRIPTION
Wrapper around Select-Object, extends property parameter.

This function allows specifying in-line transformation of the properties specified without needing to use complex hashtables.
For example, renaming a property becomes as simple as "Length as Size"

Also supported:

- Specifying a typename
- Picking the default display properties
- Adding to an existing object without destroying its type
See the description of the Property parameter for an exhaustive list of legal notations for in-line transformations.

## EXAMPLES

### Example 1: Renaming a property
```
Get-ChildItem | Select-PSFObject Name, "Length as Size"
```

Selects the properties Name and Length, renaming Length to Size in the process.

_

### Example 2: Converting type
```
Import-Csv .\file.csv | Select-PSFObject Name, "Length as Size to PSFSize"
```

Selects the properties Name and Length, renaming Length to Size and converting it to \[Example\] (a userfriendly representation of size numbers without turning the data into string)

_

### Example 3: Selecting from another object 1
```
$obj = [PSCustomObject]@{ Name = "Foo" }
Get-ChildItem | Select-PSFObject FullName, Length, "Name from obj"
```

Selects the properties FullName and Length from the input and the Name property from the object stored in $obj

_

### Example 4: Selecting from another object 2
```
$list = @()
$list += [PSCustomObject]@{ Type = "Foo"; ID = 1 }
$list += [PSCustomObject]@{ Type = "Bar"; ID = 2 }
$obj | Select-PSFObject Name, "ID from list WHERE Type = Name"
```

This allows you to LEFT JOIN contents of another variable.
Note that it can only do simple property-matching at this point.

It will select Name from the objects stored in $obj, and for each of those the ID Property on any object in $list that has a Type property of equal value as Name on the input.

_

### Example 5: Naming and styling
```
Get-ChildItem | Select-PSFObject Name, Length, FullName, Used, LastWriteTime, Mode -TypeName MyType -ShowExcludeProperty Mode, Used
```

Lists all items in the current path, selects the properties specified (whether they exist or not) , then ...

- Sets the name to "MyType"
- Hides the properties "Mode" and "Used" from the default display set, causing them to be hidden from default view

## PARAMETERS

### -InputObject
The object(s) to select from.

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
The properties to select.
- Supports hashtables, which will be passed through to Select-Object.
- Supports renaming as it is possible in SQL: "Length AS Size" will select the Length property but rename it to size.
- Supports casting to a specified type: "Address to IPAddress" or "Length to int".
Uses PowerShell type-conversion.
- Supports parsing numbers to sizes: "Length size GB:2" Converts numeric input (presumed to be bytes) to gigabyte with two decimals.
  Also supports toggling on Unit descriptors by adding another element: "Length size GB:2:1"
- Supports selecting properties from objects in other variables: "ComputerName from VarName" (Will insert the property 'ComputerName' from variable $VarName)
- Supports filtering when selecting from outside objects: "ComputerName from VarName where ObjectId = Id" (Will insert the property 'ComputerName' from the object in variable $VarName, whose ObjectId property is equal to the inputs Id property)

```yaml
Type: SelectParameter[]
Parameter Sets: DefaultParameter, SkipLastParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeProperty
Properties to not list.

```yaml
Type: String[]
Parameter Sets: DefaultParameter, SkipLastParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpandProperty
Properties to expand.

```yaml
Type: String
Parameter Sets: DefaultParameter, SkipLastParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Unique
Do not list multiples of the same value.

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

### -Last
Select the last n items.

```yaml
Type: Int32
Parameter Sets: DefaultParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -First
Select the first n items.

```yaml
Type: Int32
Parameter Sets: DefaultParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip
Skip the first (or last if used with -Last) n items.

```yaml
Type: Int32
Parameter Sets: DefaultParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipLast
Skip the last n items.

```yaml
Type: Int32
Parameter Sets: SkipLastParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wait
Indicates that the cmdlet turns off optimization.
Windows PowerShell runs commands in the order that they appear in the command pipeline and lets them generate all objects.
By default, if you include a Select-PSFObject command with the First or Index parameters in a command pipeline, Windows PowerShell stops the command that generates the objects as soon as the selected number of objects is generated.

```yaml
Type: SwitchParameter
Parameter Sets: DefaultParameter, IndexParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Index
Specifies an array of objects based on their index values.
Enter the indexes in a comma-separated list.

```yaml
Type: Int32[]
Parameter Sets: IndexParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowProperty
Only the specified properties will be shown by default.
Supersedes ShowExcludeProperty

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

### -ShowExcludeProperty
Hides the specified properties from the default display style of the output object.
Is ignored if used together with ShowProperty.

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

### -TypeName
Adds a typename to the selected object.
Will automatically prefix the module.

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

### -KeepInputObject
Keeps the original input object, adding new properties the select added without removing any.
This allows you to use this command to add properties without losing the input object's type.

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

### -Alias
Create an alias property. This can be in simple SQL notation, such as "Length as Size" or a hashtable with the alias name being the key and the referenced property being the value.

```yaml
Type: SelectAliasParameter[]
Parameter Sets: DefaultParameter, SkipLastParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptMethod
Add script methods to the object. This can be done using either:

- String syntax 'GetDouble => $this.Length * 2'
- Hashtable defining any number of methods, with the name being the key and the scriptblock being the value.

```yaml
Type: SelectScriptMethodParameter[]
Parameter Sets: DefaultParameter, SkipLastParameter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptProperty
Add script properties to the object. This parameter takes a hashtable that can be either simply Name --> Scriptblock binding (for readonly properties) or Name --> Hashtable binding, with the inner hashtable containing two keys: get & set. Each pointing at their respective scriptblock.

-ScriptProperty @{

    DoubleSize = { $this.Length * 2}

    MegaSize = @{

        get = { $this.Length * 10 }

        set = { $this.Length = $_ / 10 }

    }

}

```yaml
Type: SelectScriptPropertyParameter[]
Parameter Sets: DefaultParameter, SkipLastParameter
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

## NOTES

## RELATED LINKS

[Online Documentation](https://psframework.org/documentation/commands/PSFramework/Select-PSFObject.html)

