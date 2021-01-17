$functionDefinitions = {
	function Write-EventLogEntry
	{
		[CmdletBinding()]
		param (
			$Message
		)
		
		$level = 'Information'
		if ($Message.Level -eq 'Warning') { $level = 'Warning' }
		$errorTag = Get-ConfigValue -Name ErrorTag
		if ($Message.Tags -contains $errorTag) { $level = 'Error' }
		if ($Message.Level -eq 'Error') { $level = 'Error' }
		
		$eventID = switch ($level)
		{
			'Information' { Get-ConfigValue -Name InfoID }
			'Warning' { Get-ConfigValue -Name WarningID }
			'Error' { Get-ConfigValue -Name ErrorID }
		}
		
		$data = @(
			$Message.LogMessage
			$Message.Timestamp.ToUniversalTime().ToString((Get-ConfigValue -Name TimeFormat))
			$Message.FunctionName
			$Message.ModuleName
			($Message.Tags -join ",")
			$Message.Level
			$Message.Runspace
			$Message.TargetObject
			$Message.File
			$Message.Line
			$Message.CallStack.ToString()
			$Message.Username
			$PID
			$script:loggingID
		)
		foreach ($key in $Message.Data.Keys)
		{
			$entry = 'Data| {0} : {1}' -f $key, $Message.Data[$key]
			# Max length of line: 31839 characters https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-reporteventa
			if ($entry.Length -gt 31839) { $entry = $entry.SubString(0, 31835) + '...' }
			$data += $entry
		}
		
		try { Write-LogEntry -LogName $script:logName -Source $script:source -Type $level -Category (Get-ConfigValue -Name Category) -EventId $eventID -Data $data }
		catch { throw }
	}
	
	function Write-LogEntry
	{
		[CmdletBinding()]
		param (
			[string]
			$LogName,
			
			[string]
			$Source,
			
			[int]
			$EventID,
			
			[int]
			$Category,
			
			[System.Diagnostics.EventLogEntryType]
			$Type,
			
			[object[]]
			$Data
		)
		$id = New-Object System.Diagnostics.EventInstance($EventID, $Category, $Type)
		$evtObject = New-Object System.Diagnostics.EventLog
		$evtObject.Log = $LogName
		$evtObject.Source = $Source
		$evtObject.WriteEvent($id, $Data)
	}
	
	function Start-EventLogging
	{
		[CmdletBinding()]
		param (
			
		)
		
		$logName = Get-ConfigValue -Name LogName
		$source = Get-ConfigValue -Name Source
		
		$script:loggingID = [System.Guid]::NewGuid()
		$startingMessage = "Starting new logging provider! | Process ID: $PID | Instance Name: $($script:Instance.Name) | Logging ID: $loggingID"
		$data = $startingMessage, $PID, $script:Instance.Name, $loggingID
		try
		{
			Write-LogEntry -LogName $logName -Source $source -Type Information -Category (Get-ConfigValue -Name Category) -EventId 999 -Data $data
			$script:logName = $logName
			$script:source = $source
			return
		}
		catch
		{
			try
			{
				[System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
				Write-LogEntry -LogName $logName -Source $source -Type Information -Category (Get-ConfigValue -Name Category) -EventId 999 -Data $data
				$script:logName = $logName
				$script:source = $source
				return
			}
			catch
			{
				if (-not (Get-ConfigValue -Name UseFallback)) { throw }
				
				Write-LogEntry -LogName Application -Source Application -Type Information -Category (Get-ConfigValue -Name Category) -EventId 999 -Data $data
				$script:logName = 'Application'
				$script:source = 'Application'
			}
		}
	}
}

$begin_event = {
	Start-EventLogging
}

$message_event = {
	param (
		$Message
	)
	
	Write-EventLogEntry -Message $Message
}

$paramRegisterPSFLoggingProvider = @{
	Name			   = "eventlog"
	Version2		   = $true
	ConfigurationRoot  = 'PSFramework.Logging.EventLog'
	InstanceProperties = 'LogName', 'Source', 'UseFallback', 'Category', 'InfoID', 'WarningID', 'ErrorID', 'ErrorTag', 'TimeFormat'
	FunctionDefinitions = $functionDefinitions
	BeginEvent		   = $begin_event
	MessageEvent	   = $message_Event
	ConfigurationDefaultValues = @{
		LogName	    = 'Application'
		Source	    = 'PSFramework'
		UseFallback = $true
		Category    = 1000
		InfoID	    = 1000
		WarningID   = 2000
		ErrorID	    = 666
		ErrorTag    = 'error'
		TimeFormat  = 'yyyy-MM-dd HH:mm:ss.fff'
	}
}

Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider