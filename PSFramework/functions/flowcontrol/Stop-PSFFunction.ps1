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
        
        .PARAMETER Target
            The object that was processed when the error was thrown.
            For example, if you were trying to process a Database Server object when the processing failed, add the object here.
            This object will be in the error record (which will be written, even in non-silent mode, just won't show it).
            If you specify such an object, it becomes simple to actually figure out, just where things failed at.
        
        .PARAMETER Continue
            This will cause the function to call continue while not running with exceptions enabled (-EnableException).
            Useful when mass-processing items where an error shouldn't break the loop.
        
        .PARAMETER SilentlyContinue
            This will cause the function to call continue while running with exceptions enabled (-EnableException).
            Useful when mass-processing items where an error shouldn't break the loop.
        
        .PARAMETER ContinueLabel
            When specifying a label in combination with "-Continue" or "-SilentlyContinue", this function will call continue with this specified label.
            Helpful when trying to continue on an upper level named loop.
        
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
	[CmdletBinding(DefaultParameterSetName = 'Plain')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Message,
		
		[bool]
		$EnableException,
		
		[Parameter(ParameterSetName = 'Plain')]
		[Parameter(ParameterSetName = 'Exception')]
		[System.Management.Automation.ErrorCategory]
		$Category = ([System.Management.Automation.ErrorCategory]::NotSpecified),
		
		[Parameter(ParameterSetName = 'Exception')]
		[Alias('InnerErrorRecord')]
		[System.Management.Automation.ErrorRecord[]]
		$ErrorRecord,
		
		[string[]]
		$Tag,
		
		[string]
		$FunctionName = ((Get-PSCallStack)[0].Command),
		
		[string]
		$ModuleName = ((Get-PSCallStack)[0].InvocationInfo.MyCommand.ModuleName),
		
		[System.Exception]
		$Exception,
		
		[switch]
		$OverrideExceptionMessage,
		
		[object]
		$Target,
		
		[switch]
		$Continue,
		
		[switch]
		$SilentlyContinue,
		
		[string]
		$ContinueLabel
	)
	
	if (-not $ModuleName) { $ModuleName = "<Unknown>" }
	
	#region Apply Transforms
	#region Target Transform
	if ($Target -ne $null)
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
		foreach ($record in $ErrorRecord)
		{
			$record.Exception = Convert-PsfMessageException -Exception $record.Exception -FunctionName $FunctionName -ModuleName $ModuleName
		}
	}
	#endregion Exception Transforms
	#endregion Apply Transforms
	
	#region Message Handling
	$records = @()
	
	if ($ErrorRecord -or $Exception)
	{
		if ($ErrorRecord)
		{
			foreach ($record in $ErrorRecord)
			{
				if (-not $Exception) { $newException = New-Object System.Exception($record.Exception.Message, $record.Exception) }
				else { $newException = $Exception }
				if ($record.CategoryInfo.Category) { $Category = $record.CategoryInfo.Category }
				$records += New-Object System.Management.Automation.ErrorRecord($newException, "psframework_$FunctionName", $Category, $Target)
			}
		}
		else
		{
			$records += New-Object System.Management.Automation.ErrorRecord($Exception, "psframework_$FunctionName", $Category, $Target)
		}
		
		# Manage Debugging
		Write-PSFMessage -Level Warning -Message $Message -EnableException $EnableException -FunctionName $FunctionName -Target $Target -ErrorRecord $records -Tag $Tag -ModuleName $ModuleName -OverrideExceptionMessage:$OverrideExceptionMessage
	}
	else
	{
		$exception = New-Object System.Exception($Message)
		$records += New-Object System.Management.Automation.ErrorRecord($Exception, "psframework_$FunctionName", $Category, $Target)
		
		# Manage Debugging
		Write-PSFMessage -Level Warning -Message $Message -EnableException $EnableException -FunctionName $FunctionName -Target $Target -ErrorRecord $records -Tag $Tag -ModuleName $ModuleName -OverrideExceptionMessage:$true
	}
	#endregion Message Handling
	
	#region Silent Mode
	if ($EnableException)
	{
		if ($SilentlyContinue)
		{
			foreach ($record in $records) { Write-Error -Message $record -Category $Category -TargetObject $Target -Exception $record.Exception -ErrorId "psframework_$FunctionName" -ErrorAction Continue }
			if ($ContinueLabel) { continue $ContinueLabel }
			else { Continue }
		}
		
		# Extra insurance that it'll stop
		Set-Variable -Name "__psframework_interrupt_function_6e4%ö%qÖ%D72TgÜ9I90zÄ0N9äE6&§l§cnÖ12ßüäp4Z&5l37Gcs§Ö245iÄßlSfk6VdNTR6&00j43Ä§Ä7öÄüW0M5uüßE0bea8vÜ1Ä%" -Scope 1 -Value $true
		
		
		throw $records[0]
	}
	#endregion Silent Mode
	
	#region Non-Silent Mode
	else
	{
		# This ensures that the error is stored in the $error variable AND has its Stacktrace (simply adding the record would lack the stacktrace)
		foreach ($record in $records)
		{
			$null = Write-Error -Message $record -Category $Category -TargetObject $Target -Exception $record.Exception -ErrorId "psframework_$FunctionName" -ErrorAction Continue 2>&1
		}
		
		if ($Continue)
		{
			if ($ContinueLabel) { continue $ContinueLabel }
			else { Continue }
		}
		else
		{
			# Make sure the function knows it should be stopping
			Set-Variable -Name "__psframework_interrupt_function_6e4%ö%qÖ%D72TgÜ9I90zÄ0N9äE6&§l§cnÖ12ßüäp4Z&5l37Gcs§Ö245iÄßlSfk6VdNTR6&00j43Ä§Ä7öÄüW0M5uüßE0bea8vÜ1Ä%" -Scope 1 -Value $true
			return
		}
	}
	#endregion Non-Silent Mode
}