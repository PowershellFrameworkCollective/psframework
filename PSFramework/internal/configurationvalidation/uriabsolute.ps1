Register-PSFConfigValidation -Name "uriabsolute" -ScriptBlock {
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
	
	if (-not $uri.IsAbsoluteUri)
	{
		$Result.Message = "Not an absolute Uri: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $stringValue
	
	return $Result
}