Register-PSFConfigValidation -Name "urihttp" -ScriptBlock {
	param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	$stringValue = $Value -as [string]
	[uri]$uri = $stringValue
	
	if ($uri.Scheme -notin 'http','https' -or -not $uri.Host)
	{
		$Result.Message = "Not an HTTP Uri: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $stringValue
	
	return $Result
}