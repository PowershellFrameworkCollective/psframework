Register-PSFConfigValidation -Name "guid" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	try { [guid]$guid = $Value }
	catch
	{
		$Result.Message = "Not a GUID: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $guid
	
	return $Result
}
