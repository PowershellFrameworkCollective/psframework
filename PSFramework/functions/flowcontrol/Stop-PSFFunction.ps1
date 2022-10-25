function Stop-PSFFunction
{
<#
	.SYNOPSIS
		Function that interrupts a function.
	
	.DESCRIPTION
		Function that interrupts a function.
		
		This function is a utility function used by other functions to reduce error catching overhead.
		It is designed to allow gracefully terminating a function with a warning by default and also allow opt-in into terminating errors.
		It also allows simple integration into loops.
		
		Note:
		When calling this function with the intent to terminate the calling function in non-ExceptionEnabled mode too, you need to add a return below the call.
		
		For a more detailed explanation - including commented full-scale implementation examples - see the associated help article:
		Get-Help about_psf_flowcontrol
	
	.PARAMETER Message
		A message to pass along, explaining just what the error was.
	
	.PARAMETER String
		A stored string to use to write the log.
		Used in combination with the localization component.
		For more details see the help on Import-PSFLocalizedString and Get-PSFLocalizedString.
	
	.PARAMETER StringValues
		Values to format into the localized string referred to in the -String parameter.
	
	.PARAMETER EnableException
		Replaces user friendly yellow warnings with bloody red exceptions of doom!
		Use this if you want the function to throw terminating errors you want to catch.
	
	.PARAMETER Category
		What category does this termination belong to?
		Is automatically set when passing an error record. Helps with differentiating exceptions without having to resort to text parsing.
	
	.PARAMETER ErrorRecord
		An option to include an inner exception in the error record (and in the exception thrown, if one is thrown).
		Use this, whenever you call Stop-PSFFunction in a catch block.
		
		Note:
		Pass the full error record, not just the exception.
	
	.PARAMETER Tag
		Tags to add to the message written.
		This allows filtering and grouping by category of message, targeting specific messages.
	
	.PARAMETER FunctionName
		The name of the function to crash.
		This parameter is very optional, since it automatically selects the name of the calling function.
		The function name is used as part of the errorid.
		That in turn allows easily figuring out, which exception belonged to which function when checking out the $error variable.
	
	.PARAMETER ModuleName
		The name of the module, the function to be crashed is part of.
		This parameter is very optional, since it automatically selects the name of the calling function.
	
	.PARAMETER File
		The file in which Stop-PSFFunction was called.
		Will be automatically set, but can be overridden when necessary.
	
	.PARAMETER Line
		The line on which Stop-PSFFunction was called.
		Will be automatically set, but can be overridden when necessary.
	
	.PARAMETER Exception
		Allows specifying an inner exception as input object. This will be passed on to the logging and used for messages.
		When specifying both ErrorRecord AND Exception, Exception wins, but ErrorRecord is still used for record metadata.
	
	.PARAMETER OverrideExceptionMessage
		Disables automatic appending of exception messages.
		Use in cases where you already have a speaking message interpretation and do not need the original message.
	
	.PARAMETER Target
		The object that was processed when the error was thrown.
		For example, if you were trying to process a Database Server object when the processing failed, add the object here.
		This object will be in the error record (which will be written, even in non-silent mode, just won't show it).
		If you specify such an object, it becomes simple to actually figure out, just where things failed at.
	
	.PARAMETER AlwaysWarning
		Ensures the command always writes a visible warning, no matter what.
		by default, when -EnableException is set to $true it will hide the warning instead.
		You can enable this to always be on for your module by setting the feature flag: PSFramework.Stop-PSFFunction.ShowWarning
		For more information on feature flags, see "Get-Help Set-PSFFeature -Detailed"
		Note: When changing the level of the message using the -Level parameter, this applies to the new level as well.
	
	.PARAMETER Continue
		This will cause the function to call continue while not running with exceptions enabled (-EnableException).
		Useful when mass-processing items where an error shouldn't break the loop.
	
	.PARAMETER SilentlyContinue
		This will cause the function to call continue while running with exceptions enabled (-EnableException).
		Useful when mass-processing items where an error shouldn't break the loop.
	
	.PARAMETER ContinueLabel
		When specifying a label in combination with "-Continue" or "-SilentlyContinue", this function will call continue with this specified label.
		Helpful when trying to continue on an upper level named loop.
	
	.PARAMETER Cmdlet
		The $PSCmdlet object of the calling command.
		Used to write exceptions in a more hidden manner, avoiding exposing internal script text in the default message display.
	
	.PARAMETER StepsUpward
		When not throwing an exception and not calling continue, Stop-PSFFunction signals the calling command to stop.
		In some cases you may want to signal a step or more further up the chain (notably from helper functions within a function).
		This parameter allows you to add additional steps up the callstack that it will notify.

	.PARAMETER Level
		The level the associated message should be written at.
		This affects the log entry as well as the visibility of the message (for example 'Verbose' would not be shown by default).
		Defaults to: Warning
		Possible levels: Critical (1), Important / Output / Host (2), Significant (3), VeryVerbose (4), Verbose (5), SomewhatVerbose (6), System (7), Debug (8), InternalComment (9), Warning (666), Error (667)
	
	.EXAMPLE
		Stop-PSFFunction -Message "Foo failed bar!" -EnableException $EnableException -ErrorRecord $_
		return
		
		Depending on whether $EnableException is true or false it will:
		- Throw a bloody terminating error. Game over.
		- Write a nice warning about how Foo failed bar, then terminate the function. The return on the next line will then end the calling function.
	
	.EXAMPLE
		Stop-PSFFunction -Message "Foo failed bar!" -EnableException $EnableException -Category InvalidOperation -Target $foo -Continue
		
		Depending on whether $EnableException is true or false it will:
		- Throw a bloody terminating error. Game over.
		- Write a nice warning about how Foo failed bar, then call continue to process the next item in the loop.
		In both cases, the error record added to $error will have the content of $foo added, the better to figure out what went wrong.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(DefaultParameterSetName = 'Message', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Stop-PSFFunction')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Message')]
		[string]
		$Message,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'String')]
		[string]
		$String,
		
		[Parameter(ParameterSetName = 'String')]
		[object[]]
		$StringValues,
		
		[bool]
		$EnableException,
		
		[System.Management.Automation.ErrorCategory]
		$Category = ([System.Management.Automation.ErrorCategory]::NotSpecified),
		
		[Alias('InnerErrorRecord')]
		[System.Management.Automation.ErrorRecord[]]
		$ErrorRecord,
		
		[string[]]
		$Tag,
		
		[string]
		$FunctionName,
		
		[string]
		$ModuleName,
		
		[string]
		$File,
		
		[int]
		$Line,
		
		[System.Exception]
		$Exception,
		
		[switch]
		$OverrideExceptionMessage,
		
		[object]
		$Target,
		
		[switch]
		$AlwaysWarning,
		
		[switch]
		$Continue,
		
		[switch]
		$SilentlyContinue,
		
		[string]
		$ContinueLabel,
		
		[System.Management.Automation.PSCmdlet]
		$Cmdlet,
		
		[int]
		$StepsUpward = 0,

		[PSFramework.Message.MessageLevel]
		$Level = 'Warning'
	)
	
	if ($Cmdlet) { $myCmdlet = $Cmdlet }
	else { $myCmdlet = $PSCmdlet }
	
	#region Initialize information on the calling command
	$callStack = (Get-PSCallStack)[1]
	if (-not $FunctionName) { $FunctionName = $callStack.Command }
	if (-not $FunctionName) { $FunctionName = "<Unknown>" }
	if (-not $ModuleName) { $ModuleName = $callstack.InvocationInfo.MyCommand.ModuleName }
	if (-not $ModuleName) { $ModuleName = "<Unknown>" }
	if (-not $File) { $File = $callStack.Position.File }
	if (-not $Line) { $Line = $callStack.Position.StartLineNumber }
	if ((Test-PSFParameterBinding -ParameterName EnableException -Not) -and (Test-PSFFeature -Name "PSFramework.InheritEnableException" -ModuleName $ModuleName))
	{
		$EnableException = [bool]$PSCmdlet.GetVariableValue('EnableException')
	}
	#endregion Initialize information on the calling command
	
	#region Apply Transforms
	#region Target Transform
	if ($null -ne $Target)
	{
		$Target = Convert-PsfMessageTarget -Target $Target -FunctionName $FunctionName -ModuleName $ModuleName
	}
	#endregion Target Transform
	
	#region Exception Transforms
	if ($Exception)
	{
		$Exception = Convert-PsfMessageException -Exception $Exception -FunctionName $FunctionName -ModuleName $ModuleName
	}
	elseif ($ErrorRecord)
	{
		$int = 0
		while ($int -lt $ErrorRecord.Length)
		{
			$tempException = Convert-PsfMessageException -Exception $ErrorRecord[$int].Exception -FunctionName $FunctionName -ModuleName $ModuleName
			if ($tempException -ne $ErrorRecord[$int].Exception)
			{
				$ErrorRecord[$int] = New-Object System.Management.Automation.ErrorRecord($tempException, $ErrorRecord[$int].FullyQualifiedErrorId, $ErrorRecord[$int].CategoryInfo.Category, $ErrorRecord[$int].TargetObject)
			}
			
			$int++
		}
	}
	#endregion Exception Transforms
	#endregion Apply Transforms
	
	#region Message Handling
	$records = @()
	$showWarning = $AlwaysWarning
	if (-not $showWarning) { $showWarning = Test-PSFFeature -Name 'PSFramework.Stop-PSFFunction.ShowWarning' -ModuleName $ModuleName }
	# Explicitly bound should always win, even if -AlwaysWarning:$false
	if (Test-PSFParameterBinding -ParameterName AlwaysWarning) { $showWarning = $AlwaysWarning }
	
	$paramWritePSFMessage = @{
		Level				     = $Level
		EnableException		     = $EnableException
		FunctionName			 = $FunctionName
		Target				     = $Target
		Tag					     = $Tag
		ModuleName			     = $ModuleName
		File					 = $File
		Line					 = $Line
	}
	if ($OverrideExceptionMessage) { $paramWritePSFMessage['OverrideExceptionMessage'] = $true }
	if ($Message) { $paramWritePSFMessage["Message"] = $Message }
	else
	{
		$paramWritePSFMessage["String"] = $String
		$paramWritePSFMessage["StringValues"] = $StringValues
	}
	
	if ($ErrorRecord -or $Exception)
	{
		if ($ErrorRecord)
		{
			foreach ($record in $ErrorRecord)
			{
				if (-not $Exception) { $newException = New-Object System.Exception($record.Exception.Message, $record.Exception) }
				else { $newException = $Exception }
				if ($record.CategoryInfo.Category) { $Category = $record.CategoryInfo.Category }
				$records += New-Object System.Management.Automation.ErrorRecord($newException, "$($ModuleName)_$FunctionName", $Category, $Target)
			}
		}
		else
		{
			$records += New-Object System.Management.Automation.ErrorRecord($Exception, "$($ModuleName)_$FunctionName", $Category, $Target)
		}
		
		# Manage Debugging
		if ($EnableException -and -not $showWarning) { Write-PSFMessage -ErrorRecord $records @paramWritePSFMessage 3>$null }
		else { Write-PSFMessage -ErrorRecord $records @paramWritePSFMessage }
	}
	else
	{
        if ($String) {
            if ($StringValues) { $exception = New-Object System.Exception(([PSFramework.Localization.LocalizationHost]::Read("$ModuleName.$String", $StringValues))) }
            else { $exception = New-Object System.Exception(([PSFramework.Localization.LocalizationHost]::Read("$ModuleName.$String"))) }
        }
		else { $exception = New-Object System.Exception($Message) }

		$records += New-Object System.Management.Automation.ErrorRecord($Exception, "$($ModuleName)_$FunctionName", $Category, $Target)
		
		# Manage Debugging
		if ($EnableException -and -not $showWarning) { Write-PSFMessage -ErrorRecord $records @paramWritePSFMessage 3>$null }
		else { Write-PSFMessage -ErrorRecord $records @paramWritePSFMessage }
	}
	#endregion Message Handling
	
	#region Silent Mode
	if ($EnableException)
	{
		if ($SilentlyContinue)
		{
			foreach ($record in $records) { $myCmdlet.WriteError($record) }
			if ($ContinueLabel) { continue $ContinueLabel }
			else { continue }
		}
		
		# Extra insurance that it'll stop
		$psframework_killqueue.Enqueue($callStack.InvocationInfo.GetHashCode())
		
		# Need to use "throw" as otherwise calling function will not be interrupted without passing the cmdlet parameter
		if (-not $Cmdlet) { throw $records[0] }
		else { $Cmdlet.ThrowTerminatingError($records[0]) }
	}
	#endregion Silent Mode
	
	#region Non-Silent Mode
	else
	{
		# This ensures that the error is stored in the $error variable AND has its Stacktrace (simply adding the record would lack the stacktrace)
		foreach ($record in $records)
		{
			$null = Write-Error -Message $record -Category $Category -TargetObject $Target -Exception $record.Exception -ErrorId "$($ModuleName)_$FunctionName" -ErrorAction Continue 2>&1
		}
		
		if ($Continue)
		{
			if ($ContinueLabel) { continue $ContinueLabel }
			else { continue }
		}
		else
		{
			# Make sure the function knows it should be stopping
			if ($StepsUpward -eq 0) { $psframework_killqueue.Enqueue($callStack.InvocationInfo.GetHashCode()) }
			elseif ($StepsUpward -gt 0) { $psframework_killqueue.Enqueue((Get-PSCallStack)[($StepsUpward + 1)].InvocationInfo.GetHashCode()) }
			return
		}
	}
	#endregion Non-Silent Mode
}