$functionDefinitions = {
	function Get-LogFilePath {
		[CmdletBinding()]
		param (
			
		)
		
		$path = Get-ConfigValue -Name 'FilePath'
		$logname = Get-ConfigValue -Name 'LogName'
		
		$scriptBlock = {
			param (
				[string]
				$Match
			)
			
			$hash = @{
				'%date%' = (Get-Date -Format 'yyyy-MM-dd')
				'%dayofweek%' = (Get-Date).DayOfWeek
				'%day%'  = (Get-Date).Day
				'%hour%' = (Get-Date).Hour
				'%minute%' = (Get-Date).Minute
				'%username%' = $env:USERNAME
				'%userdomain%' = $env:USERDOMAIN
				'%computername%' = $env:COMPUTERNAME
				'%processid%' = $PID
				'%logname%' = $logname
			}
			
			$hash.$Match
		}
		
		[regex]::Replace($path, '%day%|%computername%|%hour%|%processid%|%date%|%username%|%dayofweek%|%minute%|%userdomain%|%logname%', $scriptBlock, 'IgnoreCase')
	}
	
	function Write-LogFileMessage {
		[CmdletBinding()]
		param (
			[Parameter(ValueFromPipeline = $true)]
			$Message,
			
			[bool]
			$IncludeHeader,
			
			[string]
			$FileType,
			
			[string]
			$Path,
			
			[string]
			$CsvDelimiter,
			
			$MessageItem
		)
		
		$parent = Split-Path $Path
		if (-not (Test-Path $parent)) {
			$null = New-Item $parent -ItemType Directory -Force
		}
		$fileExists = Test-Path $Path
		
		#region Type-Based Output
		switch ($FileType) {
			#region Csv
			"Csv"
			{
				if ((-not $fileExists) -and $IncludeHeader) { $Message | ConvertTo-Csv -NoTypeInformation -Delimiter $CsvDelimiter | Set-Content -Path $Path -Encoding $script:encoding }
				else { $Message | ConvertTo-Csv -NoTypeInformation -Delimiter $CsvDelimiter | Select-Object -Skip 1 | Add-Content -Path $Path -Encoding $script:encoding }
			}
			#endregion Csv
			#region Json
			"Json"
			{
				if ($fileExists -and -not $script:JsonSettings.JsonNoComma) { Add-Content -Path $Path -Value "," -Encoding $script:encoding }
				if (-not $script:JsonSettings) { $Message | ConvertTo-Json -Compress:$script:JsonSettings.JsonCompress | Add-Content -Path $Path -NoNewline:$(-not $script:JsonSettings.JsonNoComma) -Encoding $script:encoding }
				else { $Message | ConvertFrom-Enumeration | ConvertTo-Json -Compress:$script:JsonSettings.JsonCompress | Add-Content -Path $Path -NoNewline:$(-not $script:JsonSettings.JsonNoComma) -Encoding $script:encoding }
			}
			#endregion Json
			#region XML
			"XML"
			{
				[xml]$xml = $message | ConvertTo-Xml -NoTypeInformation
				$xml.Objects.InnerXml | Add-Content -Path $Path -Encoding $script:encoding
			}
			#endregion XML
			#region Html
			"Html"
			{
				[xml]$xml = $message | ConvertTo-Html -Fragment
				
				if ((-not $fileExists) -and $IncludeHeader) {
					$xml.table.tr[0].OuterXml | Add-Content -Path $Path -Encoding $script:encoding
				}
				
				$xml.table.tr[1].OuterXml | Add-Content -Path $Path -Encoding $script:encoding
			}
			#endregion Html
			#region CMTrace
			"CMTrace"
			{
				$cType = 1
				if ($MessageItem.Level -eq 'Warning') { $cType = 2 }
				if ($MessageItem.ErrorRecord) { $cType = 3 }
				$fileEntry = '<no file>'
				if ($MessageItem.File) { $fileEntry = Split-Path -Path $MessageItem.File -Leaf }
				
				$format = '<![LOG[{0}]LOG]!><time="{1:HH:mm:ss.fff}+000" date="{1:MM-dd-yyyy}" component="{6}:{2} > {7}" context="{3}" type="{4}" thread="{5}" file="{6}:{2} > {7}">'
				$line = $format -f $MessageItem.LogMessage, $MessageItem.Timestamp, $MessageItem.Line, $MessageItem.TargetObject, $cType, $MessageItem.Runspace, $fileEntry, $MessageItem.FunctionName
				$line | Add-Content -Path $Path -Encoding $script:encoding
			}
			#endregion CMTrace
		}
		#endregion Type-Based Output
	}
	
	function Invoke-LogRotate {
		[CmdletBinding()]
		param (
			
		)
		
		$basePath = Get-ConfigValue -Name 'LogRotatePath'
		if (-not $basePath) { return }
		
		#region Resolve Paths
		$scriptBlock = {
			param (
				[string]
				$Match
			)
			
			$hash = @{
				'%date%' = (Get-Date -Format 'yyyy-MM-dd')
				'%dayofweek%' = (Get-Date).DayOfWeek
				'%day%'  = (Get-Date).Day
				'%hour%' = (Get-Date).Hour
				'%minute%' = (Get-Date).Minute
				'%username%' = $env:USERNAME
				'%userdomain%' = $env:USERDOMAIN
				'%computername%' = $env:COMPUTERNAME
				'%processid%' = $PID
				'%logname%' = $logname
			}
			
			$hash.$Match
		}
		
		$basePath = [regex]::Replace($basePath, '%day%|%computername%|%hour%|%processid%|%date%|%username%|%dayofweek%|%minute%|%userdomain%|%logname%', $scriptBlock, 'IgnoreCase')
		#endregion Resolve Paths
		
		$minimumRetention = (Get-ConfigValue -Name 'LogRetentionTime') -as [PSFTimeSpan] -as [Timespan]
		if (-not $minimumRetention) { throw "No minimum retention defined" }
		if ($minimumRetention.TotalSeconds -le 0) { throw "Minimum retention must be positive! Retention: $minimumRetention" }
		
		# Don't logrotate more than every 5 minutes
		if ($script:lastRotate -gt (Get-Date).AddMinutes(-5)) { return }
		$script:lastRotate = Get-Date
		
		$limit = (Get-Date).Subtract($minimumRetention)
		Get-ChildItem -Path $basePath -Filter (Get-ConfigValue -Name 'LogRotateFilter') -Recurse:(Get-ConfigValue -Name 'LogRotateRecurse') -File | Where-Object LastWriteTime -LT $limit | Remove-Item -Force -ErrorAction Stop
	}
	
	function Update-Mutex {
		[CmdletBinding()]
		param ()
		
		$script:mutexName = Get-ConfigValue -Name 'MutexName'
		if ($script:mutexName -and -not $script:mutex) {
			$script:mutex = New-Object System.Threading.Mutex($false, $script:mutexName)
			Add-Member -InputObject $script:mutex -MemberType NoteProperty -Name Name -Value $script:mutexName
		}
		elseif ($script:mutexName -and $script:mutex.Name -ne $script:mutexName) {
			$script:mutex.Dispose()
			$script:mutex = New-Object System.Threading.Mutex($false, $script:mutexName)
			Add-Member -InputObject $script:mutex -MemberType NoteProperty -Name Name -Value $script:mutexName
		}
		elseif (-not $script:mutexName -and $script:mutex) {
			$script:mutex.Dispose()
			$script:mutex = $null
		}
	}
	
	function ConvertFrom-Enumeration {
		[CmdletBinding()]
		param (
			[Parameter(ValueFromPipeline = $true)]
			$InputObject
		)
		
		process {
			$data = @{ }
			foreach ($property in $InputObject.PSObject.Properties) {
				if ($property.Value -is [enum]) {
					$data[$property.Name] = $property.Value -as [string]
				}
				else {
					$data[$property.Name] = $property.Value
				}
			}
			[pscustomobject]$data
		}
	}
	
	function Move-LogFile {
		[CmdletBinding()]
		param (
			
		)
		
		$destinationPath = Get-ConfigValue -Name 'MoveOnFinal'
		if (-not $destinationPath) { return }
		
		if (-not (Test-Path $destinationPath)) { throw "Final log destination not found: $destinationPath" }
		$folder = Get-Item -Path $destinationPath
		if (-not $folder.PSIsContainer) { throw "Final log destination is not a folder: $destinationPath" }
		
		foreach ($filePath in $script:logPathList.Keys) {
			if (-not (Test-Path -Path $filePath)) { continue }
			
			Move-Item -Path $filePath -Destination $folder.FullName -Force -ErrorAction Stop
		}
	}
	
	function Copy-LogFile {
		[CmdletBinding()]
		param (
			
		)
		
		$destinationPath = Get-ConfigValue -Name 'CopyOnFinal'
		if (-not $destinationPath) { return }
		
		if (-not (Test-Path $destinationPath)) { throw "Final log destination not found: $destinationPath" }
		$folder = Get-Item -Path $destinationPath
		if (-not $folder.PSIsContainer) { throw "Final log destination is not a folder: $destinationPath" }
		
		foreach ($filePath in $script:logPathList.Keys) {
			if (-not (Test-Path -Path $filePath)) { continue }
			
			Copy-Item -Path $filePath -Destination $folder.FullName -Force -ErrorAction Stop
		}
	}
}

#region Events
$begin_event = {
	$script:lastRotate = (Get-Date).AddMinutes(-10)
	$script:logPathList = @{ }
}

$start_event = {
	$script:logfile_headers = Get-ConfigValue -Name 'Headers' | ForEach-Object {
		switch ($_) {
			'Tags'
			{
				@{
					Name	   = 'Tags'
					Expression = { $_.Tags -join "," }
				}
			}
			'Message'
			{
				@{
					Name	   = 'Message'
					Expression = { $_.LogMessage }
				}
			}
			'Timestamp'
			{
				@{
					Name	   = 'Timestamp'
					Expression = {
						if (Get-ConfigValue -Name 'UTC') {
							if (-not (Get-ConfigValue -Name 'TimeFormat')) { $_.Timestamp.ToUniversalTime() }
							else { $_.Timestamp.ToUniversalTime().ToString((Get-ConfigValue -Name 'TimeFormat')) }
						}
						else {
							if (-not (Get-ConfigValue -Name 'TimeFormat')) { $_.Timestamp }
							else { $_.Timestamp.ToString((Get-ConfigValue -Name 'TimeFormat')) }
						}
					}
				}
			}
			default { $_ }
		}
	}
	
	$script:logfile_paramWriteLogFileMessage = @{
		IncludeHeader = Get-ConfigValue -Name 'IncludeHeader'
		FileType	  = Get-ConfigValue -Name 'FileType'
		CsvDelimiter  = Get-ConfigValue -Name 'CsvDelimiter'
		Path		  = Get-LogFilePath
	}
	# Cache path for final move action
	$script:logPathList[$script:logfile_paramWriteLogFileMessage.Path] = $script:logfile_paramWriteLogFileMessage.Path
	
	$script:encoding = Get-ConfigValue -Name 'Encoding'
	
	$script:JsonSettings = @{
		JsonCompress = Get-ConfigValue -Name JsonCompress
		JsonString   = Get-ConfigValue -Name JsonString
		JsonNoComma  = Get-ConfigValue -Name JsonNoComma
	}
	Update-Mutex
}

$message_event = {
	param (
		$Message
	)
	
	if ($script:mutex) { $null = $script:mutex.WaitOne() }
	try { $Message | Select-Object $script:logfile_headers | Write-LogFileMessage @script:logfile_paramWriteLogFileMessage -MessageItem $Message }
	finally { if ($script:mutex) { $script:mutex.ReleaseMutex() } }
}

$end_event = {
	Invoke-LogRotate
}

$final_event = {
	Move-LogFile
	Copy-LogFile
}
#endregion Events

$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.FilePath' -Value "" -Initialize -Validation string -Description "The path to where the logfile is written. Supports some placeholders such as %Date% to allow for timestamp in the name. For full documentation on the supported wildcards, see the documentation on https://psframework.org"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.Logname' -Value "" -Initialize -Validation string -Description "A special string you can use as a placeholder in the logfile path (by using '%logname%' as placeholder)"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.IncludeHeader' -Value $true -Initialize -Validation bool -Description "Whether a written csv file will include headers"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.Headers' -Value @('ComputerName', 'File', 'FunctionName', 'Level', 'Line', 'Message', 'ModuleName', 'Runspace', 'Tags', 'TargetObject', 'Timestamp', 'Type', 'Username') -Initialize -Validation stringarray -Description "The properties to export, in the order to select them."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.FileType' -Value "CSV" -Initialize -Validation psframework.logfilefiletype -Description "In what format to write the logfile. Supported styles: CSV, XML, Html, Json or CMTrace. Html, XML and Json will be written as fragments."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.CsvDelimiter' -Value "," -Initialize -Validation string -Description "The delimiter to use when writing to csv."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.TimeFormat' -Value "$([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.ShortDatePattern) $([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.LongTimePattern)" -Initialize -Validation string -Description "The format used for timestamps in the logfile"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.Encoding' -Value "UTF8" -Initialize -Validation string -Description "In what encoding to write the logfile."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.UTC' -Value $false -Initialize -Validation bool -Description "Whether the timestamp in the logfile should be converted to UTC"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.LogRotatePath' -Value "" -Initialize -Validation string -Description "The path where to logrotate. Specifying this setting will cause the logging provider to also rotate older logfiles"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.LogRetentionTime' -Value "30d" -Initialize -Validation timespan -Description "The minimum age for a logfile to be considered for deletion as part of logrotation"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.LogRotateFilter' -Value "*" -Initialize -Validation string -Description "A filter to apply to all files logrotated"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.LogRotateRecurse' -Value $false -Initialize -Validation bool -Description "Whether the logrotate aspect should recursively look for files to logrotate"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.MutexName' -Value '' -Initialize -Validation string -Description "Name of a mutex to use. Use this to handle parallel logging into the same file from multiple processes, by picking the same name in each process."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.JsonCompress' -Value $false -Initialize -Validation bool -Description "Will compress the json entries, condensing each entry into a single line."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.JsonString' -Value $false -Initialize -Validation bool -Description "Will convert all enumerated properties to string values when converting to json. This causes the level property to be 'Debug','Host', ... rather than 8,2,..."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.JsonNoComma' -Value $false -Initialize -Validation bool -Description "Prevent adding commas between two json entries."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.MoveOnFinal' -Value '' -Initialize -Validation string -Description "Path to a target folder to move logfiles to when shutting down the logging provider instance. This happens automatically when PSFramework ends or the provider instance is disabled again."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.CopyOnFinal' -Value '' -Initialize -Validation string -Description "Path to a target folder to copy logfiles to when shutting down the logging provider instance. This happens automatically when PSFramework ends or the provider instance is disabled again."
}

$paramRegisterPSFLoggingProvider = @{
	Name			   = "logfile"
	Version2		   = $true
	ConfigurationRoot  = 'PSFramework.Logging.LogFile'
	InstanceProperties = 'CsvDelimiter', 'FilePath', 'FileType', 'Headers', 'IncludeHeader', 'Logname', 'TimeFormat', 'Encoding', 'UTC', 'LogRotatePath', 'LogRetentionTime', 'LogRotateFilter', 'LogRotateRecurse', 'MutexName', 'JsonCompress', 'JsonString', 'JsonNoComma', 'MoveOnFinal', 'CopyOnFinal'
	FunctionDefinitions = $functionDefinitions
	BeginEvent		   = $begin_event
	StartEvent		   = $start_event
	MessageEvent	   = $message_event
	EndEvent		   = $end_event
	FinalEvent		   = $final_event
	ConfigurationDefaultValues = @{
		IncludeHeader = $true
		Headers	      = 'ComputerName', 'File', 'FunctionName', 'Level', 'Line', 'Message', 'ModuleName', 'Runspace', 'Tags', 'TargetObject', 'Timestamp', 'Type', 'Username'
		FileType	  = 'CSV'
		CsvDelimiter  = ','
		TimeFormat    = "$([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.ShortDatePattern) $([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.LongTimePattern)"
		Encoding	  = 'UTF8'
		LogRetentionTime = '30d'
		LogRotateFilter = '*'
		LogRotateRecurse = $false
	}
	ConfigurationSettings = $configuration_Settings
}

Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider