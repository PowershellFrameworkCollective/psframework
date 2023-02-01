Register-PSFConfigValidation -Name "consolecolor" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	try { [System.ConsoleColor]$color = $Value }
	catch
	{
		$Result.Message = "Not a console color: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $color
	
	return $Result
}