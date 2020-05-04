$functionDefinitions = {
	function Get-LogFilePath
	{
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
		
		[regex]::Replace($path, '%day%|%computername%|%hour%|%processid%|%date%|%username%|%dayofweek%|%minute%|%userdomain%|%logname%', $scriptBlock)
	}
	
	function Write-LogFileMessage
	{
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
			
			[string[]]
			$Headers
		)
		
		$parent = Split-Path $Path
		if (-not (Test-Path $parent))
		{
			$null = New-Item $parent -ItemType Directory -Force
		}
		$fileExists = Test-Path $Path
		
		#region Type-Based Output
		switch ($FileType)
		{
			#region Csv
			"Csv"
			{
				if ((-not $fileExists) -and $IncludeHeader) { $Message | ConvertTo-Csv -NoTypeInformation -Delimiter $CsvDelimiter | Set-Content -Path $Path -Encoding UTF8 }
				else { $Message | ConvertTo-Csv -NoTypeInformation -Delimiter $CsvDelimiter | Select-Object -Skip 1 | Add-Content -Path $Path -Encoding UTF8 }
			}
			#endregion Csv
			#region Json
			"Json"
			{
				if ($fileExists) { Add-Content -Path $Path -Value "," -Encoding UTF8 }
				$Message | ConvertTo-Json | Add-Content -Path $Path -NoNewline -Encoding UTF8
			}
			#endregion Json
			#region XML
			"XML"
			{
				[xml]$xml = $message | ConvertTo-Xml -NoTypeInformation
				$xml.Objects.InnerXml | Add-Content -Path $Path -Encoding UTF8
			}
			#endregion XML
			#region Html
			"Html"
			{
				[xml]$xml = $message | ConvertTo-Html -Fragment
				
				if ((-not $fileExists) -and $IncludeHeader)
				{
					$xml.table.tr[0].OuterXml | Add-Content -Path $Path -Encoding UTF8
				}
				
				$xml.table.tr[1].OuterXml | Add-Content -Path $Path -Encoding UTF8
			}
			#endregion Html
		}
		#endregion Type-Based Output
	}
}

$start_event = {
	$script:logfile_headers = Get-ConfigValue -Name 'Headers' | ForEach-Object {
		switch ($_)
		{
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
						if (-not (Get-ConfigValue -Name 'TimeFormat')) { $_.Timestamp }
						else { $_.Timestamp.ToString((Get-ConfigValue -Name 'TimeFormat')) }
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
		Headers	      = $script:logfile_headers
		Path		  = Get-LogFilePath
	}
}

$message_Event = {
	param (
		$Message
	)
	
	$Message | Select-Object $script:logfile_headers | Write-LogFileMessage @script:logfile_paramWriteLogFileMessage
}

$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.FilePath' -Value "" -Initialize -Validation string -Description "The path to where the logfile is written. Supports some placeholders such as %Date% to allow for timestamp in the name. For full documentation on the supported wildcards, see the documentation on https://psframework.org"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.Logname' -Value "" -Initialize -Validation string -Description "A special string you can use as a placeholder in the logfile path (by using '%logname%' as placeholder)"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.IncludeHeader' -Value $true -Initialize -Validation bool -Description "Whether a written csv file will include headers"
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.Headers' -Value @('ComputerName', 'File', 'FunctionName', 'Level', 'Line', 'Message', 'ModuleName', 'Runspace', 'Tags', 'TargetObject', 'Timestamp', 'Type', 'Username') -Initialize -Validation stringarray -Description "The properties to export, in the order to select them."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.FileType' -Value "CSV" -Initialize -Validation psframework.logfilefiletype -Description "In what format to write the logfile. Supported styles: CSV, XML, Html or Json. Html, XML and Json will be written as fragments."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.CsvDelimiter' -Value "," -Initialize -Validation string -Description "The delimiter to use when writing to csv."
	Set-PSFConfig -Module PSFramework -Name 'Logging.LogFile.TimeFormat' -Value "$([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.ShortDatePattern) $([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.LongTimePattern)" -Initialize -Validation string -Description "The format used for timestamps in the logfile"
}

$paramRegisterPSFLoggingProvider = @{
	Name			   = "logfile"
	Version2		   = $true
	ConfigurationRoot  = 'PSFramework.Logging.LogFile'
	InstanceProperties = 'CsvDelimiter', 'FilePath', 'FileType', 'Headers', 'IncludeHeader', 'Logname', 'TimeFormat'
	FunctionDefinitions = $functionDefinitions
	StartEvent		   = $start_event
	MessageEvent	   = $message_Event
	ConfigurationDefaultValues = @{
		IncludeHeader = $true
		Headers	      = 'ComputerName', 'File', 'FunctionName', 'Level', 'Line', 'Message', 'ModuleName', 'Runspace', 'Tags', 'TargetObject', 'Timestamp', 'Type', 'Username'
		FileType	  = 'CSV'
		CsvDelimiter  = ','
		TimeFormat    = "$([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.ShortDatePattern) $([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.LongTimePattern)"
	}
	ConfigurationSettings = $configuration_Settings
}

Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider