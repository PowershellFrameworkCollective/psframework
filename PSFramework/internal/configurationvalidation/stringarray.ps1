Register-PSFConfigValidation -Name "stringarray" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success  = $True
		Value    = $null
		Message  = ""
	}
	
	try
	{
		$data = @()
		# Seriously, this should work for almost anybody and anything
		foreach ($item in $Value)
		{
			$data += [string]$item
		}
	}
	catch
	{
		$Result.Message = "Not a string array: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $data
	
	return $Result
}