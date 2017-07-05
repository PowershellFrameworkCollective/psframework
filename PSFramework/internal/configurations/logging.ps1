#region Preparing the handlers
$scriptBlock = @{ }
#region Logging.MaxErrorCount
$scriptBlock["Logging.MaxErrorCount"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [int]$number = $Value }
	catch
	{
		$Result.Message = "Not an integer: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MaxErrorCount = $Value
	
	return $Result
}
#endregion Logging.MaxErrorCount

#region Logging.MaxMessageCount
$scriptBlock["Logging.MaxMessageCount"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [int]$number = $Value }
	catch
	{
		$Result.Message = "Not an integer: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MaxMessageCount = $Value
	
	return $Result
}
#endregion Logging.MaxMessageCount

#region Logging.MessageLogEnabled
$scriptBlock["Logging.MessageLogEnabled"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	if ($Value.GetType().FullName -ne "System.Boolean")
	{
		$Result.Message = "Not a Boolean: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MessageLogEnabled = $Value
	
	return $Result
}
#endregion Logging.MessageLogEnabled

#region Logging.ErrorLogEnabled
$scriptBlock["Logging.ErrorLogEnabled"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	if ($Value.GetType().FullName -ne "System.Boolean")
	{
		$Result.Message = "Not a Boolean: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::ErrorLogEnabled = $Value
	
	return $Result
}
#endregion Logging.ErrorLogEnabled

#region Logging.FileSystem.MaxMessagefileBytes
$scriptBlock["Logging.FileSystem.MaxMessagefileBytes"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [int]$number = $Value }
	catch
	{
		$Result.Message = "Not an integer: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MaxMessagefileBytes = $Value
	
	return $Result
}
#endregion Logging.FileSystem.MaxMessagefileBytes

#region Logging.FileSystem.MaxMessagefileCount
$scriptBlock["Logging.FileSystem.MaxMessagefileCount"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [int]$number = $Value }
	catch
	{
		$Result.Message = "Not an integer: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MaxMessagefileCount = $Value
	
	return $Result
}
#endregion Logging.FileSystem.MaxMessagefileCount

#region Logging.FileSystem.MaxErrorFileBytes
$scriptBlock["Logging.FileSystem.MaxErrorFileBytes"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [int]$number = $Value }
	catch
	{
		$Result.Message = "Not an integer: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MaxErrorFileBytes = $Value
	
	return $Result
}
#endregion Logging.FileSystem.MaxErrorFileBytes

#region Logging.FileSystem.MaxTotalFolderSize
$scriptBlock["Logging.FileSystem.MaxTotalFolderSize"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [int]$number = $Value }
	catch
	{
		$Result.Message = "Not an integer: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MaxTotalFolderSize = $Value
	
	return $Result
}
#endregion Logging.FileSystem.MaxTotalFolderSize

#region Logging.FileSystem.MaxLogFileAge
$scriptBlock["Logging.FileSystem.MaxLogFileAge"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [timespan]$timespan = $Value }
	catch
	{
		$Result.Message = "Not a Timespan: $Value"
		$Result.Success = $False
		return $Result
	}
	
	if ($timespan.TotalMilliseconds -le 0)
	{
		$Result.Message = "Timespan cannot be set to 0 milliseconds or less: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MaxLogFileAge = $Value
	
	return $Result
}
#endregion Logging.FileSystem.MaxLogFileAge

#region Logging.FileSystem.MessageLogFileEnabled
$scriptBlock["Logging.FileSystem.MessageLogFileEnabled"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	if ($Value.GetType().FullName -ne "System.Boolean")
	{
		$Result.Message = "Not a Boolean: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::MessageLogFileEnabled = $Value
	
	return $Result
}
#endregion Logging.FileSystem.MessageLogFileEnabled

#region Logging.FileSystem.ErrorLogFileEnabled
$scriptBlock["Logging.FileSystem.ErrorLogFileEnabled"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	if ($Value.GetType().FullName -ne "System.Boolean")
	{
		$Result.Message = "Not a Boolean: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::ErrorLogFileEnabled = $Value
	
	return $Result
}
#endregion Logging.FileSystem.ErrorLogFileEnabled

#region Logging.FileSystem.LogPath
$scriptBlock["Logging.FileSystem.LogPath"] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSOBject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [System.IO.Path]::GetFullPath($Value) }
	catch
	{
		$Result.Message = "Illegal path: $Value"
		$Result.Success = $False
		return $Result
	}
	
	if (Test-Path -Path $Value -PathType Leaf)
	{
		$Result.Message = "Is a file, not a folder: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.LogHost]::LoggingPath = $Value
	
	return $Result
}
#endregion Logging.FileSystem.LogPath
#endregion Preparing the handlers

#region Setting the configuration
Set-PSFConfig -Module PSFramework -Name 'Logging.MaxErrorCount' -Value 128 -Initialize -Handler $scriptBlock["Logging.MaxErrorCount"] -Description "The maximum number of error records maintained in-memory. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
Set-PSFConfig -Module PSFramework -Name 'Logging.MaxMessageCount' -Value 1024 -Initialize -Handler $scriptBlock["Logging.MaxMessageCount"] -Description "The maximum number of messages that can be maintained in the in-memory message queue. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
Set-PSFConfig -Module PSFramework -Name 'Logging.MessageLogEnabled' -Value $true -Initialize -Handler $scriptBlock["Logging.MessageLogEnabled"] -Description "Governs, whether a log of recent messages is kept in memory. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
Set-PSFConfig -Module PSFramework -Name 'Logging.ErrorLogEnabled' -Value $true -Initialize -Handler $scriptBlock["Logging.ErrorLogEnabled"] -Description "Governs, whether a log of recent errors is kept in memory. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."

Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxMessagefileBytes' -Value 5MB -Initialize -Handler $scriptBlock["Logging.FileSystem.MaxMessagefileBytes"] -Description "The maximum size of a given logfile. When reaching this limit, the file will be abandoned and a new log created. Set to 0 to not limit the size. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxMessagefileCount' -Value 5 -Initialize -Handler $scriptBlock["Logging.FileSystem.MaxMessagefileCount"] -Description "The maximum number of logfiles maintained at a time. Exceeding this number will cause the oldest to be culled. Set to 0 to disable the limit. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxErrorFileBytes' -Value 20MB -Initialize -Handler $scriptBlock["Logging.FileSystem.MaxErrorFileBytes"] -Description "The maximum size all error files combined may have. When this number is exceeded, the oldest entry is culled. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxTotalFolderSize' -Value 100MB -Initialize -Handler $scriptBlock["Logging.FileSystem.MaxTotalFolderSize"] -Description "This is the upper limit of length all items in the log folder may have combined across all processes."
Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MaxLogFileAge' -Value (New-TimeSpan -Days 7) -Initialize -Handler $scriptBlock["Logging.FileSystem.MaxLogFileAge"] -Description "Any logfile older than this will automatically be cleansed. This setting is global."
Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.MessageLogFileEnabled' -Value $true -Initialize -Handler $scriptBlock["Logging.FileSystem.MessageLogFileEnabled"] -Description "Governs, whether a log file for the system messages is written. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.ErrorLogFileEnabled' -Value $true -Initialize -Handler $scriptBlock["Logging.FileSystem.ErrorLogFileEnabled"] -Description "Governs, whether log files for errors are written. This setting is on a per-Process basis. Runspaces share, jobs or other consoles counted separately."
Set-PSFConfig -Module PSFramework -Name 'Logging.FileSystem.LogPath' -Value "$($env:APPDATA)\WindowsPowerShell\PSFramework\Logs" -Initialize -Handler $scriptBlock["Logging.FileSystem.LogPath"] -Description "The path where the PSFramework writes all its logs and debugging information."
#endregion Setting the configuration