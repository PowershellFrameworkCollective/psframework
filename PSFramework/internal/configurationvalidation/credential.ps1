Register-PSFConfigValidation -Name "credential" -ScriptBlock {
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
		if ($Value.GetType().FullName -ne "System.Management.Automation.PSCredential")
		{
			$Result.Message = "Not a credential: $Value"
			$Result.Success = $False
			return $Result
		}
	}
	catch
	{
		$Result.Message = "Not a credential: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $Value
	
	return $Result
}