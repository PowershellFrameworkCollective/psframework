Register-PSFConfigValidation -Name "rstimeout" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}

	$textValue = "$Value"
	$legal = [enum]::GetNames([PSFramework.Runspace.RSTimeout]) | Where-Object { $_ -ne 'Undefined' }

	if ($legal -notcontains $textValue) {
		$Result.Message = "Not a runspace workflow timeout setting: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $textValue -as [PSFramework.Runspace.RSTimeout]
	
	return $Result
}