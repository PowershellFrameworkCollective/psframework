Register-PSFConfigValidation -Name "psframework.logfilefiletype" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success  = $True
		Value    = $null
		Message  = ""
	}
	
	try { [PSFramework.Logging.LogFileFileType]$type = $Value }
	catch
	{
		$Result.Message = "Not a logfile file type: $Value . Specify one of these values: $(([enum]::GetNames([PSFramework.Logging.LogFileFileType])) -join ", ")"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $type
	
	return $Result
}