Register-PSFConfigValidation -Name "guidarray" -ScriptBlock {
	param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	try
	{
		$data = @()
		foreach ($item in $Value)
		{
			$data += [guid]$item
		}
	}
	catch
	{
		$Result.Message = "Not a guid array: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $data
	
	return $Result
}