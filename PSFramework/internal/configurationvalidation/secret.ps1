Register-PSFConfigValidation -Name "secret" -ScriptBlock {
	param (
		$Value
	)
	
	$Result = [PSCustomObject]@{
		Success = $True
		Value   = $null
		Message = ""
	}
	
	if ($null -eq $Value) {
		$Result.Message = "Secrets cannot be empty!"
		$Result.Success = $False
		return $Result
	}
	
	if ($Value.GetType() -notin [string], [System.Security.SecureString], [System.Management.Automation.PSCredential]) {
		$Result.Message = "Secrets must be either a string, a securestring or a pscredential object!"
		$Result.Success = $False
		return $Result
	}
	
	if ($Value -is [string]) {
		$Value = $Value | ConvertTo-SecureString -AsPlainText -Force
	}
	if ($Value -is [System.Security.SecureString]) {
		$Value = New-Object System.Management.Automation.PSCredential('<none>', $Value)
	}
	
	$Result.Value = $Value
	
	return $Result
}