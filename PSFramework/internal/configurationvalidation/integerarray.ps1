Register-PSFConfigValidation -Name "integerarray" -ScriptBlock {
	param (
		$var
	)
	
	$test = $true
	try { [int[]]$res = $var }
	catch { $test = $false }
	
	[pscustomobject]@{
		Success = $test
		Value   = $res
		Message = "Casting $var as [int[]] failure. Input is being identified as $($var.GetType())"
	}
}