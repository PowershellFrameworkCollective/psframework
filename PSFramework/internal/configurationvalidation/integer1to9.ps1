Register-PSFConfigValidation -Name "integer1to9" -ScriptBlock {
	param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	try { [int]$number = $Value }
	catch
	{
		$Result.Message = "Not an integer: $Value"
		$Result.Success = $False
		return $Result
	}
	
	if (($number -lt 1) -or ($number -gt 9))
	{
		$Result.Message = "Out of range. Specify a number ranging from 1 to 9"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $Number
	
	return $Result
}