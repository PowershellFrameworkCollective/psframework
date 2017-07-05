#region Preparing the handlers
$scriptBlock = @{ }
#region Runspace.StopTimeoutSeconds
$scriptBlock["Runspace.StopTimeoutSeconds"] = {
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
	
	[PSFramework.Runspace.RunspaceHost]::StopTimeoutSeconds = $Value
	
	return $Result
}
#endregion Runspace.StopTimeoutSeconds
#endregion Preparing the handlers

#region Setting the configuration
Set-PSFConfig -Module PSFramework -Name 'Runspace.StopTimeoutSeconds' -Value 30 -Initialize -Handler $scriptBlock["Runspace.StopTimeoutSeconds"] -Description "Time in seconds that Stop-PSFRunspace will wait for a scriptspace to selfterminate before killing it."
#endregion Setting the configuration