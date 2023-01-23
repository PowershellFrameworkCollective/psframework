Register-PSFConfigValidation -Name "datetime" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	try { [DateTime]$DateTime = $Value }
	catch
	{
		$Result.Message = "Not a DateTime: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $DateTime
	
	return $Result
}