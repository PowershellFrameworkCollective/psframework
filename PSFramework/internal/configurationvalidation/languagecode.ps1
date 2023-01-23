Register-PSFConfigValidation -Name "languagecode" -ScriptBlock {
	param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	$legal = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name | Where-Object { $_ -and ($_.Trim()) }
	
	if ($Value -in $legal)
	{
		$Result.Value = [string]$Value
	}
	else
	{
		$Result.Success = $false
		$Result.Message = [PSFramework.Localization.LocalizationHost]::Read('PSFramework.Configuration_ValidateLanguage')
	}
	
	return $Result
}