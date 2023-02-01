Register-PSFConfigValidation -Name "bool" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	try
	{
		if ($Value.GetType().FullName -notin "System.Boolean", 'System.Management.Automation.SwitchParameter')
		{
			$Result.Message = "Not a boolean: $Value"
			$Result.Success = $False
			return $Result
		}
	}
	catch
	{
		$Result.Message = "Not a boolean: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $Value -as [bool]
	
	return $Result
}