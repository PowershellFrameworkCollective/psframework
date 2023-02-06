Register-PSFConfigValidation -Name "long" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	try { [long]$number = $Value }
	catch
	{
		$Result.Message = "Not a long: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $number
	
	return $Result
}