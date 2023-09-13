---
external help file: PSFramework.dll-Help.xml
Module Name: PSFramework
online version:
schema: 2.0.0
---

# Invoke-PSFProtectedCommand

## SYNOPSIS
Combines should process, try/catch error handling and logging in one package.

## SYNTAX

### Message
```
Invoke-PSFProtectedCommand -ScriptBlock <ScriptBlock> -Action <String> [-Target <Object>]
 [-EnableException <Boolean>] [-PSCmdlet <PSCmdlet>] [-Continue] [-ContinueLabel <String>] [-Tag <String[]>]
 [-RetryCount <Int32>] [-RetryWait <TimeSpanParameter>] [-RetryWaitEscalation <Double>]
 [-RetryErrorType <String[]>] [-RetryCondition <ScriptBlock>] [-ErrorEvent <ScriptBlock>]
 [-Level <MessageLevel>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### String
```
Invoke-PSFProtectedCommand -ScriptBlock <ScriptBlock> -ActionString <String> [-ActionStringValues <Object[]>]
 [-Target <Object>] [-EnableException <Boolean>] [-PSCmdlet <PSCmdlet>] [-Continue] [-ContinueLabel <String>]
 [-Tag <String[]>] [-RetryCount <Int32>] [-RetryWait <TimeSpanParameter>] [-RetryWaitEscalation <Double>]
 [-RetryErrorType <String[]>] [-RetryCondition <ScriptBlock>] [-ErrorEvent <ScriptBlock>]
 [-Level <MessageLevel>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This command is designed to do away with the script code overhead of:

- Prompting for ShouldProcess if needed
- Including try/catch error handling for the purpose of the PSFramework opt-in exceptions concept
- Logging execution
As such it is intended to help produce more readable code in less time.

Note: This command can only be used from an advanced function unless specifying the -PSCmdlet parameter.

## EXAMPLES

### Example 1 : Killing with maximum prejudice
```powershell
PS C:\> Invoke-PSFProtectedCommand -Action "Doing Something" -Target $computer -ScriptBlock {
    Get-Something -ComputerName $computer -ErrorAction Stop
} -EnableException $true
```

Invokes the specified scriptblock, honoring ShouldProcess, logging execution and potential failure.
Failure will lead to a terminating exception.

_

### Example 2 : Killing it softly
```powershell
PS C:\> Invoke-PSFProtectedCommand -Action "Doing Something" -Target $computer -ScriptBlock {
    Get-Something -ComputerName $computer -ErrorAction Stop
}
PS C:\> if (Test-PSFFunctionInterrupt) { return }
```

Invokes the specified scriptblock, honoring ShouldProcess, logging execution and potential failure.
Failure will lead to a warning with the command terminating silently, unless the calling command's module opted into inheriting the '-EnableException' parameter (in which case the caller of the command calling Invoke-PSFProtectedCommand gets to pick whether this is throwing an exception or not)

## PARAMETERS

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
If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

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

### -Continue
When execution fails, unless exceptions where opted into, this command will call continue, moving on with the next item to process.

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
This parameters disables user-friendly warnings and enables the throwing of exceptions.
This is less user friendly, but allows catching exceptions in calling scripts.

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
This command will automatically pick up the $PSCmdlet variable of its caller.
Use this parameter to override this and specify what $PSCmdlet variable to use.
The $PSCmdlet variable will be used for terminating exceptions.

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

### -ScriptBlock
The actual scriptblock to execute.
Make sure any errors you want to trigger failure are terminating.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Target
The target object to work against.

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

### -WhatIf
if this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

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

### -ContinueLabel
When used together with -Continue, this allows you to pick the loop to continue with.

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

### -RetryCount
How many times the command should attempt to try an action again, before giving up.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetryErrorType
When using -RetryCount to attempt a failed action again, this is a bit unspecific.
Often we want to retry to deal with specific scenarios ... with specific errors.
Using this parameter, it becomes possible to specify just what exception types can only trigger a retry attempt.

Note: Exceptions of type ActionPreferenceStopException will be unwrapped to the original exception BEFORE performing the comparison.

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

### -RetryWait
The interval the command will wait between failed attempts.
Defaults to 5 seconds.

```yaml
Type: TimeSpanParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Tag
What tags - if any - to include in all messages.

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

### -RetryCondition
Only when this scriptblock returns $true will it try again.
The script receives two input items:

- $_ : The exception (not error record) thrown
- $args[0] : The Target object specified in the -Target parameter


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

### -ErrorEvent
Scriptblock that should be executed in case of failure.
$_ will be the error that happened.

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

### -Level
At what level should verbose messages be written.
Defaults to SomewhatVerbose.

```yaml
Type: MessageLevel
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RetryWaitEscalation
When retrying failed attempts, the previous wait time is multiplied by this value.
This allows waiting longer and longer periods, each time it failed.
Defaults to 1.

```yaml
Type: Double
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

### Keine

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
