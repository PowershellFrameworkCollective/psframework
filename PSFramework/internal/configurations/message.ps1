#region Prepare handlers
$scriptBlock = @{ }
#region message.info.maximum
$scriptBlock['message.info.maximum'] = {
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
	
	if (($number -lt 0) -or ($number -gt 9))
	{
		$Result.Message = "Out of range. Either specify a number ranging from 1 to 9, or disable it by setting it to 0"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::MaximumInformation = $Value
	
	return $Result
}
#endregion message.info.maximum

#region message.verbose.maximum
$scriptBlock['message.verbose.maximum'] = {
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
	
	if (($number -lt 0) -or ($number -gt 9))
	{
		$Result.Message = "Out of range. Either specify a number ranging from 1 to 9, or disable it by setting it to 0"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::MaximumVerbose = $Value
	
	return $Result
}
#endregion message.verbose.maximum

#region message.debug.maximum
$scriptBlock['message.debug.maximum'] = {
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
	
	if (($number -lt 0) -or ($number -gt 9))
	{
		$Result.Message = "Out of range. Either specify a number ranging from 1 to 9, or disable it by setting it to 0"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::MaximumDebug = $Value
	
	return $Result
}
#endregion message.debug.maximum

#region message.info.minimum
$scriptBlock['message.info.minimum'] = {
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
	
	if (($number -lt 0) -or ($number -gt 9))
	{
		$Result.Message = "Out of range. Either specify a number ranging from 1 to 9, or disable it by setting it to 0"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::MinimumInformation = $Value
	
	return $Result
}
#endregion message.info.minimum

#region message.verbose.minimum
$scriptBlock['message.verbose.minimum'] = {
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
	
	if (($number -lt 0) -or ($number -gt 9))
	{
		$Result.Message = "Out of range. Either specify a number ranging from 1 to 9, or disable it by setting it to 0"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::MinimumVerbose = $Value
	
	return $Result
}
#endregion message.verbose.minimum

#region message.debug.minimum
$scriptBlock['message.debug.minimum'] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSObject -Property @{
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
	
	if (($number -lt 0) -or ($number -gt 9))
	{
		$Result.Message = "Out of range. Either specify a number ranging from 1 to 9, or disable it by setting it to 0"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::MinimumDebug = $Value
	
	return $Result
}
#endregion message.debug.minimum

#region message.info.color
$scriptBlock['message.info.color'] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSObject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [System.ConsoleColor]$number = $Value }
	catch
	{
		$Result.Message = "Not a console color: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::InfoColor = $Value
	
	return $Result
}
#endregion message.info.color

#region message.developercolor
$scriptBlock['message.developercolor'] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSObject -Property @{
		Success = $True
		Message = ""
	}
	
	try { [System.ConsoleColor]$number = $Value }
	catch
	{
		$Result.Message = "Not a console color: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::DeveloperColor = $Value
	
	return $Result
}
#endregion message.developercolor

#region developer.mode.enable
$scriptBlock['developer.mode.enable'] = {
	Param (
		$Value
	)
	
	$Result = New-Object PSObject -Property @{
		Success = $True
		Message = ""
	}
	
	if ($Value.GetType().FullName -ne "System.Boolean")
	{
		$Result.Message = "Not a console color: $Value"
		$Result.Success = $False
		return $Result
	}
	
	[PSFramework.Message.MessageHost]::DeveloperMode = $Value
	
	return $Result
}
#endregion developer.mode.enable
#endregion Prepare handlers

#region Apply settings
Set-PSFConfig -Module PSFramework -Name 'message.info.maximum' -Value 3 -Initialize -Handler $scriptBlock['message.info.maximum'] -Description "The maximum message level to still display to the user directly."
Set-PSFConfig -Module PSFramework -Name 'message.verbose.maximum' -Value 6 -Initialize -Handler $scriptBlock['message.verbose.maximum'] -Description "The maxium message level where verbose information is still written."
Set-PSFConfig -Module PSFramework -Name 'message.debug.maximum' -Value 9 -Initialize -Handler $scriptBlock['message.debug.maximum'] -Description "The maximum message level where debug information is still written."
Set-PSFConfig -Module PSFramework -Name 'message.info.minimum' -Value 1 -Initialize -Handler $scriptBlock['message.info.minimum'] -Description "The minimum required message level for messages that will be shown to the user."
Set-PSFConfig -Module PSFramework -Name 'message.verbose.minimum' -Value 4 -Initialize -Handler $scriptBlock['message.verbose.minimum'] -Description "The minimum required message level where verbose information is written."
Set-PSFConfig -Module PSFramework -Name 'message.debug.minimum' -Value 1 -Initialize -Handler $scriptBlock['message.debug.minimum'] -Description "The minimum required message level where debug information is written."
Set-PSFConfig -Module PSFramework -Name 'message.info.color' -Value 'Cyan' -Initialize -Handler $scriptBlock['message.info.color'] -Description "The color to use when writing text to the screen on PowerShell."
Set-PSFConfig -Module PSFramework -Name 'message.developercolor' -Value 'Gray' -Initialize -Handler $scriptBlock['message.developercolor'] -Description "The color to use when writing text with developer specific additional information to the screen on PowerShell."
Set-PSFConfig -Module PSFramework -Name 'developer.mode.enable' -Value $false -Initialize -Handler $scriptBlock['developer.mode.enable'] -Description "Developermode enables advanced logging and verbosity features. There is little benefit for enabling this as a regular user. but developers can use it to more easily troubleshoot issues."
#endregion Apply settings