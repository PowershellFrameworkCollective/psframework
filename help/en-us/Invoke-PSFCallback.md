---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version:
schema: 2.0.0
---

# Invoke-PSFCallback

## SYNOPSIS
Invokes all registered callback scripts applicable to the calling command.

## SYNTAX

```
Invoke-PSFCallback [-Data <Object>] [-EnableException <Boolean>] [-PSCmdlet <PSCmdlet>] [<CommonParameters>]
```

## DESCRIPTION
Invokes all registered callback scripts applicable to the calling command.

Use Register-PSFCallback to register scriptblocks that get applied.

By calling Invoke-PSFCallback - which will not do anything unless somebody registers callback scriptblocks - a module can provide extensions points to which other modules can attach, without the implementing module needing to know those external modules.

## EXAMPLES

### Example 1 : Basic Invocation
```powershell
PS C:\> Invoke-PSFCallback
```

Simply by calling the command, any registered scriptblocks that apply to your command get triggered.

_

### Example 2 : Providing Information
```powershell
PS C:\> Invoke-PSFCallback -Data $Server
```

Executes all applicable, registered callback scriptblocks.

Provides the information stored in $Server to the scriptblock(s) being this executed.

_

### Example 3 : The full invocation
```powershell
PS C:\> Invoke-PSFCallback -Data $Server -EnableException $true -PSCmdlet $PSCmdlet
```

Executes all applicable, registered callback scriptblocks.

Provides the information stored in $Server to the scriptblock(s) being this executed.

If any of the executed callback scriptblocks fails with a terminating exception, the command calling Invoke-PSFCallback also fails in a terminating exception (no try/catch necessary).

## PARAMETERS

### -Data
Additional data to provide to the callback scriptblock.

This can be useful to implement input-driven workflows.
For example, it would allow a callback scriptblock to load configuration, based on the server being processed.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableException
Enables - if $true - terminating exceptions when a single callback scriptblock fails.
The terminating exception is thrown in the context of the calling command, not Invoke-PSFCallback, so it is unneccessary - and impossible - to handle within a try/catch block.

If set to $false (default), failure flags the calling command for failure, as detected by Test-PSFFunctionInterrupt. In that case, Invoke-PSFCallback will log the error, but not directly terminate the calling command.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PSCmdlet
The $PSCmdlet object of the calling command.
If this value is not provided, it will autoamtically be picked up.
Providing it improves performance slightly, as it removes the need to look it up.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
