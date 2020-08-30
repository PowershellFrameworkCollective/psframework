# Action that is performed on registration of the provider using Register-PSFLoggingProvider
$registrationEvent = {
	
}

#region Logging Execution
# Action that is performed when starting the logging script (or the very first time if enabled after launching the logging script)
$begin_event = {
	#region Helper Functions
	function Clean-FileSystemErrorXml
	{
		[CmdletBinding()]
		Param (
			$Path
		)
		
		$totalLength = $Null
		$files = Get-ChildItem -Path $Path.FullName -Filter "$($env:ComputerName)_$($pid)_error_*.xml" | Sort-Object LastWriteTime
		$totalLength = $files | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum
		if (([PSFramework.Message.LogHost]::MaxErrorFileBytes) -gt $totalLength) { return }
		
		$removed = 0
		foreach ($file in $files)
		{
			$removed += $file.Length
			Remove-Item -Path $file.FullName -Force -Confirm:$false
			
			if (($totalLength - $removed) -lt ([PSFramework.Message.LogHost]::MaxErrorFileBytes)) { break }
		}
	}
	
	function Clean-FileSystemMessageLog
	{
		[CmdletBinding()]
		Param (
			$Path
		)
		
		if ([PSFramework.Message.LogHost]::MaxMessagefileCount -eq 0) { return }
		
		$files = Get-ChildItem -Path $Path.FullName -Filter "$($env:ComputerName)_$($pid)_message_*.log" | Sort-Object LastWriteTime
		if (([PSFramework.Message.LogHost]::MaxMessagefileCount) -ge $files.Count) { return }
		
		$removed = 0
		foreach ($file in $files)
		{
			$removed++
			Remove-Item -Path $file.FullName -Force -Confirm:$false
			
			if (($files.Count - $removed) -le ([PSFramework.Message.LogHost]::MaxMessagefileCount)) { break }
		}
	}
	
	function Clean-FileSystemGlobalLog
	{
		[CmdletBinding()]
		Param (
			$Path
		)
		
		# Kill too old files
		Get-ChildItem -Path $Path.FullName | Where-Object Name -Match "^$([regex]::Escape($env:ComputerName))_.+" | Where-Object LastWriteTime -LT ((Get-Date) - ([PSFramework.Message.LogHost]::MaxLogFileAge)) | Remove-Item -Force -Confirm:$false
		
		# Handle the global overcrowding
		$files = Get-ChildItem -Path $Path.FullName | Where-Object Name -Match "^$([regex]::Escape($env:ComputerName))_.+" | Sort-Object LastWriteTime
		if (-not ($files)) { return }
		$totalLength = $files | Measure-Object Length -Sum | Select-Object -ExpandProperty Sum
		
		if (([PSFramework.Message.LogHost]::MaxTotalFolderSize) -gt $totalLength) { return }
		
		$removed = 0
		foreach ($file in $files)
		{
			$removed += $file.Length
			Remove-Item -Path $file.FullName -Force -Confirm:$false
			
			if (($totalLength - $removed) -lt ([PSFramework.Message.LogHost]::MaxTotalFolderSize)) { break }
		}
	}
	#endregion Helper Functions
	
	$filesystem_SelectTargetObject = @{
		Name = 'TargetObject'
		Expression = {
			if ($null -eq $_.TargetObject) { return }
			if ([PSFramework.Message.LogHost]::FileSystemSerializationDepth -lt 0) { return $_.TargetObject }
			if ([PSFramework.Message.LogHost]::FileSystemSerializationDepth -eq 0) { return ($_.TargetObject | ConvertTo-PSFClixml) }
			$_.TargetObject | ConvertTo-PSFClixml -Depth ([PSFramework.Message.LogHost]::FileSystemSerializationDepth)
		}
	}
	$filesystem_SelectTimestamp = @{
		Name = 'Timestamp'
		Expression = {
			$_.Timestamp.ToString([PSFramework.Message.LogHost]::TimeFormat)
		}
	}
}

# Action that is performed at the beginning of each logging cycle
$start_event = {
	$filesystem_path = [PSFramework.Message.LogHost]::LoggingPath
	if (-not (Test-Path $filesystem_path))
	{
		$filesystem_root = New-Item $filesystem_path -ItemType Directory -Force -ErrorAction Stop
	}
	else { $filesystem_root = Get-Item -Path $filesystem_path }
	
	try { [int]$filesystem_num_Error = (Get-ChildItem -Path $filesystem_path.FullName -Filter "$($env:ComputerName)_$($pid)_error_*.xml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name | Select-String -Pattern "(\d+)" -AllMatches).Matches[1].Value }
	catch { }
	try { [int]$filesystem_num_Message = (Get-ChildItem -Path $filesystem_path.FullName -Filter "$($env:ComputerName)_$($pid)_message_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name | Select-String -Pattern "(\d+)" -AllMatches).Matches[1].Value }
	catch { }
	if (-not ($filesystem_num_Error)) { $filesystem_num_Error = 0 }
	if (-not ($filesystem_num_Message)) { $filesystem_num_Message = 0 }
}

# Action that is performed for each message item that is being logged
$message_Event = {
	Param (
		$Message
	)
	
	$filesystem_CurrentFile = Join-Path $filesystem_root.FullName "$($env:ComputerName)_$($pid)_message_$($filesystem_num_Message).log"
	if (Test-Path $filesystem_CurrentFile)
	{
		$filesystem_item = Get-Item $filesystem_CurrentFile
		if ($filesystem_item.Length -gt ([PSFramework.Message.LogHost]::MaxMessagefileBytes))
		{
			$filesystem_num_Message++
			$filesystem_CurrentFile = Join-Path $($filesystem_root.FullName) "$($env:ComputerName)_$($pid)_message_$($filesystem_num_Message).log"
		}
	}
	
	if ($Message)
	{
		if ([PSFramework.Message.LogHost]::FileSystemModernLog)
		{
			if (-not (Test-Path $filesystem_CurrentFile))
			{
				$Message | Select-PSFObject ComputerName, Username, $filesystem_SelectTimestamp, Level, 'LogMessage as Message', Type, FunctionName, ModuleName, File, Line, @{ n = "Tags"; e = { $_.Tags -join "," } }, $filesystem_SelectTargetObject, Runspace, @{ n = "Callstack"; e = { $_.CallStack.ToString().Split("`n") -join " þ "} } | Export-Csv -Path $filesystem_CurrentFile -NoTypeInformation
			}
			else { Add-Content -Path $filesystem_CurrentFile -Value (ConvertTo-Csv ($Message | Select-PSFObject ComputerName, Username, $filesystem_SelectTimestamp, Level, 'LogMessage as Message', Type, FunctionName, ModuleName, File, Line, @{ n = "Tags"; e = { $_.Tags -join "," } }, $filesystem_SelectTargetObject, Runspace, @{ n = "Callstack"; e = { $_.CallStack.ToString().Split("`n") -join " þ " } }) -NoTypeInformation)[1] }
		}
		else { Add-Content -Path $filesystem_CurrentFile -Value (ConvertTo-Csv ($Message | Select-PSFObject ComputerName, Timestamp, Level, 'LogMessage as Message', Type, FunctionName, ModuleName, File, Line, @{ n = "Tags"; e = { $_.Tags -join "," } }, $filesystem_SelectTargetObject, Runspace) -NoTypeInformation)[1] }
	}
}

# Action that is performed for each error item that is being logged
$error_Event = {
	Param (
		$ErrorItem
	)
	
	if ($ErrorItem)
	{
		$ErrorItem | Export-Clixml -Path (Join-Path $filesystem_root.FullName "$($env:ComputerName)_$($pid)_error_$($filesystem_num_Error).xml") -Depth 3
		$filesystem_num_Error++
	}
	
	Clean-FileSystemErrorXml -Path $filesystem_root
}

# Action that is performed at the end of each logging cycle
$end_event = {
	Clean-FileSystemMessageLog -Path $filesystem_root
	Clean-FileSystemGlobalLog -Path $filesystem_root
}

# Action that is performed when stopping the logging script
$final_event = {
	
}
#endregion Logging Execution

#region Function Extension / Integration
# Script that generates the necessary dynamic parameter for Set-PSFLoggingProvider
$configurationParameters = {
	$configroot = "PSFramework.Logging.FileSystem"
	
	$configurations = Get-PSFConfig -FullName "$configroot.*"
	
	$RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	
	foreach ($config in $configurations)
	{
		$ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
		$ParamAttrib.ParameterSetName = '__AllParameterSets'
		$AttribColl = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
		$AttribColl.Add($ParamAttrib)
		$RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter(($config.FullName.Replace($configroot, "").Trim(".")), $config.Value.GetType(), $AttribColl)
		
		$RuntimeParamDic.Add(($config.FullName.Replace($configroot, "").Trim(".")), $RuntimeParam)
	}
	return $RuntimeParamDic
}

# Script that is executes when configuring the provider using Set-PSFLoggingProvider
$configurationScript = {
	$configroot = "PSFramework.Logging.FileSystem"
	
	$configurations = Get-PSFConfig -FullName "$configroot.*"
	
	foreach ($config in $configurations)
	{
		if ($PSBoundParameters.ContainsKey(($config.FullName.Replace($configroot, "").Trim("."))))
		{
			Set-PSFConfig -Module $config.Module -Name $config.Name -Value $PSBoundParameters[($config.FullName.Replace($configroot, "").Trim("."))]
		}
	}
}

# Script that returns a boolean value. "True" if all prerequisites are installed, "False" if installation is required
$isInstalledScript = {
	return $true
}

# Script that provides dynamic parameter for Install-PSFLoggingProvider
$installationParameters = {
	# None needed
}

# Script that performs the actual installation, based on the parameters (if any) specified in the $installationParameters script
$installationScript = {
	# Nothing to be done - if you need to install your filesystem, you probably have other issues you need to deal with first ;)
}
#endregion Function Extension / Integration

# Configuration settings to initialize
$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxMessagefileBytes' -Value 5MB -Initialize -Validation "long" -Handler { [PSFramework.Message.LogHost]::MaxMessagefileBytes = $args[0] } -Description "The maximum size of a given logfile. When reaching this limit, the file will be abandoned and a new log created. Set to 0 to not limit the size. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxMessagefileCount' -Value 5 -Initialize -Validation "integerpositive" -Handler { [PSFramework.Message.LogHost]::MaxMessagefileCount = $args[0] } -Description "The maximum number of logfiles maintained at a time. Exceeding this number will cause the oldest to be culled. Set to 0 to disable the limit. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxErrorFileBytes' -Value 20MB -Initialize -Validation "long" -Handler { [PSFramework.Message.LogHost]::MaxErrorFileBytes = $args[0] } -Description "The maximum size all error files combined may have. When this number is exceeded, the oldest entry is culled. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxTotalFolderSize' -Value 100MB -Initialize -Validation "long" -Handler { [PSFramework.Message.LogHost]::MaxTotalFolderSize = $args[0] } -Description "This is the upper limit of length all items in the log folder may have combined across all processes."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxLogFileAge' -Value (New-TimeSpan -Days 7) -Initialize -Validation "timespan" -Handler { [PSFramework.Message.LogHost]::MaxLogFileAge = $args[0] } -Description "Any logfile older than this will automatically be cleansed. This setting is global."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MessageLogFileEnabled' -Value $true -Initialize -Validation "bool" -Handler { [PSFramework.Message.LogHost]::MessageLogFileEnabled = $args[0] } -Description "Governs, whether a log file for the system messages is written. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.ErrorLogFileEnabled' -Value $true -Initialize -Validation "bool" -Handler { [PSFramework.Message.LogHost]::ErrorLogFileEnabled = $args[0] } -Description "Governs, whether log files for errors are written. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.ModernLog' -Value $false -Initialize -Validation "bool" -Handler { [PSFramework.Message.LogHost]::FileSystemModernLog = $args[0] } -Description "Enables the modern, more powereful version of the filesystem log, including headers and extra columns"
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.LogPath' -Value $script:path_Logging -Initialize -Validation "string" -Handler { [PSFramework.Message.LogHost]::LoggingPath = $args[0] } -Description "The path where the PSFramework writes all its logs and debugging information."
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.TimeFormat' -Value "$([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.ShortDatePattern) $([System.Globalization.CultureInfo]::CurrentUICulture.DateTimeFormat.LongTimePattern)" -Initialize -Validation string -Handler { [PSFramework.Message.LogHost]::TimeFormat = $args[0] } -Description "The format used for timestamps in the logfile"
	Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.TargetSerializationDepth' -Value -1 -Initialize -Validation "integer" -Handler { [PSFramework.Message.LogHost]::FileSystemSerializationDepth = $args[0] } -Description "Whether the target object should be stored as a serialized object. 0 or less will see it logged as string, 1 or greater will see it logged as compressed CLIXML."
	
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.Enabled' -Value $true -Initialize -Validation "bool" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].Enabled = $args[0] } } -Description "Whether the logging provider should be enabled on registration"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.AutoInstall' -Value $false -Initialize -Validation "bool" -Handler { } -Description "Whether the logging provider should be installed on registration"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.InstallOptional' -Value $true -Initialize -Validation "bool" -Handler { } -Description "Whether installing the logging provider is mandatory, in order for it to be enabled"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.IncludeModules' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].IncludeModules = ($args[0] | Write-Output) } } -Description "Module whitelist. Only messages from listed modules will be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.ExcludeModules' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].ExcludeModules = ($args[0] | Write-Output) } } -Description "Module blacklist. Messages from listed modules will not be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.IncludeTags' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].IncludeTags = ($args[0] | Write-Output) } } -Description "Tag whitelist. Only messages with these tags will be logged"
	Set-PSFConfig -Module LoggingProvider -Name 'FileSystem.ExcludeTags' -Value @() -Initialize -Validation "stringarray" -Handler { if ([PSFramework.Logging.ProviderHost]::Providers['filesystem']) { [PSFramework.Logging.ProviderHost]::Providers['filesystem'].ExcludeTags = ($args[0] | Write-Output) } } -Description "Tag blacklist. Messages with these tags will not be logged"
}

$paramRegisterPSFLoggingProvider = @{
	Name				    = "filesystem"
	RegistrationEvent	    = $registrationEvent
	BeginEvent			    = $begin_event
	StartEvent			    = $start_event
	MessageEvent		    = $message_Event
	ErrorEvent			    = $error_Event
	EndEvent			    = $end_event
	FinalEvent			    = $final_event
	ConfigurationParameters = $configurationParameters
	ConfigurationScript	    = $configurationScript
	IsInstalledScript	    = $isInstalledScript
	InstallationScript	    = $installationScript
	InstallationParameters  = $installationParameters
	ConfigurationSettings   = $configuration_Settings
}

Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider