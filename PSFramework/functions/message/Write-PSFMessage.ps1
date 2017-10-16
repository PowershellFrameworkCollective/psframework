function Write-PSFMessage
{
	<#
		.SYNOPSIS
			This function receives messages, then logs and reports them.
		
		.DESCRIPTION
			This function receives messages, then logs and reports them.
			Other functions hand off all their information output for processing to this function.

			This function will then handle:
			- Warning output
			- Error management for non-terminating errors (For errors that terminate execution or continue on with the next object use "Stop-PSFFunction")
			- Logging
			- Verbose output
			- Message output to users

			For the complex description on how this works and how users and developers can influence it, run:
			Get-Help about_psf_message
		
		.PARAMETER Message
			The message to write/log. The function name and timestamp will automatically be prepended.
		
		.PARAMETER Level
			This parameter represents the verbosity of the message. The lower the number, the more important it is for a human user to read the message.
			By default, the levels are distributed like this:
			- 1-3 Direct verbose output to the user (using Write-Host)
			- 4-6 Output only visible when requesting extra verbosity (using Write-Verbose)
			- 1-9 Debugging information, written using Write-Debug

			In addition, it is possible to select the level "Warning" which moves the message out of the configurable range:
			The user will always be shown this message, unless he silences the entire verbosity.

			Possible levels:
			Critical (1), Important / Output / Host (2), Significant (3), VeryVerbose (4), Verbose (5), SomewhatVerbose (6), System (7), Debug (8), InternalComment (9), Warning (666)
			Either one of the strings or its respective number will do as input.
	
		.PARAMETER Tag
			Tags to add to the message written.
			This allows filtering and grouping by category of message, targeting specific messages.
		
		.PARAMETER FunctionName
			The name of the calling function.
			Will be automatically set, but can be overridden when necessary.
	
		.PARAMETER ModuleName
			The name of the module, the calling function is part of.
			Will be automatically set, but can be overridden when necessary.
		
		.PARAMETER ErrorRecord
			If an error record should be noted with the message, add the full record here.
			Especially designed for use with Warning-mode, it can legally be used in either mode.
			The error will be added to the $Error variable and enqued in the logging/debugging system.
		
		.PARAMETER Once
			Setting this parameter will cause this function to write the message only once per session.
			The string passed here and the calling function's name are used to create a unique ID, which is then used to register the action in the configuration system.
			Thus will the lockout only be written if called once and not burden the system unduly.
			This lockout will be written as a hidden value, to see it use Get-PSFConfig -Force.
		
		.PARAMETER Target
			Add the object the message is all about, in order to simplify debugging / troubleshooting.
			For example, when calling this from a function targeting a remote computer, the computername could be specified here, allowing all messages to easily be correlated to the object processed.
		
		.PARAMETER EnableException
			This parameters disables user-friendly warnings and enables the throwing of exceptions.
			This is less user friendly, but allows catching exceptions in calling scripts.
		
		.EXAMPLE
			PS C:\> Write-PSFMessage -Level Verbose -Message "Connecting to $computer"
	
			Writes the message "Connecting to $computer" to verbose.
			Will also log the message.
	
		.EXAMPLE
			PS C:\> Write-PSFMessage -Level Warning -Message "Failed to retrieve additional network adapter information from $computer"
	
			Writes the message "Failed to retrieve additional network adapter information from $computer" as a warning.
			Will also log the message.
	
		.EXAMPLE
			PS C:\> Write-PSFMessage -Level Verbose -Message "Connecting to $computer" -Target $computer
	
			Writes the message "Connecting to $computer" to verbose.
			Includes the variable $computer in the message. This has no effect on the text shown but will be available for debugging purposes.
			Will also log the message.
	
		.EXAMPLE
			PS C:\> Write-PSFMessage -Level Host -Message "This command has been deprecated, use 'Get-NewExample' instead" -Once 'Get-Example'
	
			Writes the message "This command has been deprecated, use 'Get-NewExample' instead" to the screen.
			This message will only be shown once per powershell process.
			Will also log the message.
	
		.EXAMPLE
			PS C:\> Write-PSFMessage -Level Warning -Message "Failed to retrieve additional network adapter information from $computer" -Target $computer -ErrorRecord $_
	
			Writes the message "Failed to retrieve additional network adapter information from $computer" as a warning.
			Will also append the message of the exception to the text.
			Will also add the error record to the error log
			Will also log the message.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
	[CmdletBinding()]
	Param (
		[PSFramework.Message.MessageLevel]
		$Level = [PSFramework.Message.MessageLevel]::Verbose,
		
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Message,
		
		[string[]]
		$Tag,
		
		[string]
		$FunctionName = ((Get-PSCallStack)[0].Command),
		
		[string]
		$ModuleName = ((Get-PSCallStack)[0].InvocationInfo.MyCommand.ModuleName),
		
		[System.Management.Automation.ErrorRecord[]]
		$ErrorRecord,
		
		[System.Exception]
		$Exception,
		
		[string]
		$Once,
		
		[switch]
		$OverrideExceptionMessage,
		
		[object]
		$Target,
		
		[bool]
		$EnableException
	)
	
	<#
	# Workflow guide #
	#----------------#
	
	Since this command has gotten a bit complex, here's a short guide to its workflow (with considerations attached)
	
	1. Process Statics
	   For performance reasons, some static information is retrieved/determined at the start.
	2. Apply Transforms
	   Users/Modules can specify global transforms, that can - depending on the target or exception type - transform
	   those objects. For example, it could unwrap a wrapped exception or convert a live-state object into a static value object.
	3. Exception Integration
	   If the user specified an exception to override anything within the error record (or compßletely without an error record),
	   this integrates those into a standard error record. This has to be fairly at the top, in order for subsequent steps to have
	   the finalized version and not care about this complexity.
	4. Handle Message content
	   With all preliminaries dealt with, the finalized message versions are processed. Here it will create two message versions:
	   - A colorful, for host output
	   - A base version, stripped of all color tags, for logging
	   If developer mode is enabled, it will instead create more detailed messages
	5. Handle Errors
	   With all properties determined, it will now create the logging entry for errors (if any were specified).
	6. Message Modes
	   Based on levels specified, it will now write to the message to the determined channels and create entries in the message log.
	#>
	
	#region Preliminary statics
	$timestamp = Get-Date
	$developerMode = [PSFramework.Message.MessageHost]::DeveloperMode
	
	$max_info = [PSFramework.Message.MessageHost]::MaximumInformation
	$max_verbose = [PSFramework.Message.MessageHost]::MaximumVerbose
	$max_debug = [PSFramework.Message.MessageHost]::MaximumDebug
	$min_info = [PSFramework.Message.MessageHost]::MinimumInformation
	$min_verbose = [PSFramework.Message.MessageHost]::MinimumVerbose
	$min_debug = [PSFramework.Message.MessageHost]::MinimumDebug
	$info_color = [PSFramework.Message.MessageHost]::InfoColor
	$dev_color = [PSFramework.Message.MessageHost]::DeveloperColor
	$silent = $false
	if ($psframework_silence) { $silent = $true }
	if ([PSFramework.Message.MessageHost]::DisableVerbosity) { $silent = $true }
	if (-not $ModuleName) { $ModuleName = "<Unknown>" }
	$fromStopFunction = (Get-PSCallStack)[1].Command -eq "Stop-PSFFunction"
	#endregion Preliminary statics
	
	#region Apply Transforms
	#region Target Transform
	if ((-not $fromStopFunction) -and ($Target -ne $null))
	{
		$Target = Convert-PsfMessageTarget -Target $Target -FunctionName $FunctionName -ModuleName $ModuleName
	}
	#endregion Target Transform
	
	#region Exception Transforms
	if (-not $fromStopFunction)
	{
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
	}
	#endregion Exception Transforms
	
	#region Message Level Transform
	# Never transform warning messages
	if ($Level -ne [PSFramework.Message.MessageLevel]::Warning)
	{
		$Level = Convert-PsfMessageLevel -OriginalLevel $Level -FromStopFunction $fromStopFunction -Tags $Tag -FunctionName $FunctionName -ModuleName $ModuleName
	}
	#endregion Message level Transform
	#endregion Apply Transforms
	
	#region Exception Integration
	# While conclusive error handling must happen after message handling,
	# in order to integrate the exception message into the actual message,
	# it becomes necessary to first integrate the exception and error record parameters into a uniform view
	
	# Note: Stop-PSFFunction never specifies this parameter, thus it is not necessary to check,
	# whether this function was called from Stop-PSFFunction.
	if ($Exception)
	{
		if ($ErrorRecord)
		{
			$ErrorRecord[0].Exception = $Exception
		}
		else
		{
			$ErrorRecord = @()
			$ErrorRecord += New-Object System.Management.Automation.ErrorRecord($Exception, "psframework_$FunctionName", "NotSpecified", $Target)
		}
	}
	
	#endregion Exception Integration
	
	#region Handle Message Content
	$coloredMessage = $Message
	$baseMessage = $Message
	foreach ($match in ($baseMessage | Select-String '<c=["''](.*?)["'']>(.*?)</c>' -AllMatches).Matches)
	{
		$baseMessage = $baseMessage -replace ([regex]::Escape($match.Value)), $match.Groups[2].Value
	}
	
	if ($developerMode)
	{
		$channels_future = @()
		if ((-not $Silent) -and ($Level -eq [PSFramework.Message.MessageLevel]::Warning)) { $channels_future += "Warning" }
		if ((-not $Silent) -and ($max_info -ge $Level) -and ($min_info -le $Level)) { $channels_future += "Information" }
		if (($max_verbose -ge $Level) -and ($min_verbose -le $Level)) { $channels_future += "Verbose" }
		if (($max_debug -ge $Level) -and ($min_debug -le $Level)) { $channels_future += "Debug" }
		
		if ((Test-PSFParameterBinding "Target") -and ($null -ne $Target))
		{
			if ($Target.ToString() -ne $Target.GetType().FullName) { $targetString = " [T: $($Target.ToString())] " }
			else { $targetString = " [T: <$($Target.GetType().FullName.Split(".")[-1])>] " }
		}
		else { $targetString = "" }
		
		$newMessage = @"
[$($timestamp.ToString("HH:mm:ss"))][$FunctionName][L: $Level]$targetString[C: $channels_future][EE: $EnableException][O: $(Test-PSFParameterBinding Once)]
    $baseMessage
"@
		$newColoredMessage = @"
[<c='sub'>$($timestamp.ToString("HH:mm:ss"))</c>][<c='sub'>$FunctionName</c>][<c='sub'>L:</c> <c='em'>$Level</c>]<c='em'>$targetString</c>[<c='sub'>C:</c> <c='em'>$channels_future</c>][<c='sub'>EE:</c> <c='em'>$EnableException</c>][<c='sub'>O:</c> <c='em'>$(Test-PSFParameterBinding Once)</c>]
    $coloredMessage
"@
	}
	else
	{
		$newMessage = "[$($timestamp.ToString("HH:mm:ss"))][$FunctionName] $baseMessage"
		$newColoredMessage = "[<c='sub'>$($timestamp.ToString("HH:mm:ss"))</c>][<c='sub'>$FunctionName</c>] $coloredMessage"
	}
	
	
	if ($ErrorRecord -and (-not $OverrideExceptionMessage) -and ($Message -notmatch ([regex]::Escape("$($ErrorRecord[0].Exception.Message)"))))
	{
		$baseMessage += " | $($ErrorRecord[0].Exception.Message)"
		$newMessage += " | $($ErrorRecord[0].Exception.Message)"
		$newColoredMessage += " | $($ErrorRecord[0].Exception.Message)"
	}
	#endregion Handle Message Content

	#region Handle Errors
	if ($ErrorRecord -and (-not $fromStopFunction))
	{
		foreach ($record in $ErrorRecord)
		{
			$Exception = New-Object System.Exception($Message, $record.Exception)
			$newRecord = New-Object System.Management.Automation.ErrorRecord($Exception, "psframework_$FunctionName", $record.CategoryInfo.Category, $Target)
			
			if ($EnableException) { Write-Error -Message $newRecord -Category $record.CategoryInfo.Category -TargetObject $Target -Exception $Exception -ErrorId "psframework_$FunctionName" -ErrorAction Continue }
			else { $null = Write-Error -Message $newRecord -Category $record.CategoryInfo.Category -TargetObject $Target -Exception $Exception -ErrorId "psframework_$FunctionName" -ErrorAction Continue 2>&1 }
		}
	}
	if ($ErrorRecord)
	{
		[PSFramework.Message.LogHost]::WriteErrorEntry($ErrorRecord, $FunctionName, $ModuleName, $Tag, $timestamp, $baseMessage, ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId), $env:COMPUTERNAME)
	}
	#endregion Handle Errors
	
	$channels = @()
	
	#region Warning Mode
	if ($Warning -or ($Level -like "Warning"))
	{
		if (-not $Silent)
		{
			if ($PSBoundParameters.ContainsKey("Once"))
			{
				$OnceName = "MessageOnce.$FunctionName.$Once"
				
				if (-not (Get-PSFConfigValue -Name $OnceName))
				{
					Write-Warning $newMessage
					Set-PSFConfig -Name $OnceName -Value $True -Hidden -ErrorAction Ignore
				}
			}
			else
			{
				Write-Warning $newMessage
			}
			$channels += "Warning"
		}
		elseif ($developerMode)
		{
			Write-Host $newMessage -ForegroundColor $dev_color
		}
		
		Write-Debug $newMessage
		$channels += "Debug"
	}
	#endregion Warning Mode
	
	#region Message Mode
	else
	{
		if ((-not $Silent) -and ($max_info -ge $Level) -and ($min_info -le $Level))
		{
			if (Test-PSFParameterBinding "Once")
			{
				$OnceName = "MessageOnce.$FunctionName.$Once"
				
				if (-not (Get-PSFConfigValue -Name $OnceName))
				{
					Write-PSFHostColor -String $newColoredMessage -DefaultColor $info_color -ErrorAction Ignore
					Set-PSFConfig -Name $OnceName -Value $True -Hidden -ErrorAction Ignore
				}
			}
			else
			{
				Write-PSFHostColor -String $newColoredMessage -DefaultColor $info_color -ErrorAction Ignore
			}
			$channels += "Information"
		}
		elseif ($developerMode)
		{
			Write-PSFHostColor -String $newColoredMessage -DefaultColor $dev_color
		}
		
		if (($max_verbose -ge $Level) -and ($min_verbose -le $Level))
		{
			Write-Verbose $newMessage
			$channels += "Verbose"
		}
		
		if (($max_debug -ge $Level) -and ($min_debug -le $Level))
		{
			Write-Debug $newMessage
			$channels += "Debug"
		}
	}
	#endregion Message Mode
	
	$channel_Result = $channels -join ", "
	if ($channel_Result)
	{
		$entry = [PSFramework.Message.LogHost]::WriteLogEntry($baseMessage, $channel_Result, $timestamp, $FunctionName, $ModuleName, $Tag, $Level, ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId), $env:COMPUTERNAME, $Target)
	}
	else
	{
		$entry = [PSFramework.Message.LogHost]::WriteLogEntry($baseMessage, "None", $timestamp, $FunctionName, $ModuleName, $Tag, $Level, ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId), $env:COMPUTERNAME, $Target)
	}
	
	foreach ($subscription in [PSFramework.Message.MessageHost]::Events.Values)
	{
		if ($subscription.Applies($entry))
		{
			$scriptBlock = [scriptblock]::Create($subscription.ScriptBlock.ToString())
			$ExecutionContext.InvokeCommand.InvokeScript($false, $scriptBlock, $null, $entry)
		}
	}
}