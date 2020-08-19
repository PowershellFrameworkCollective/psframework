function BeTrueForAll
{
	[CmdletBinding()]
	param (
		$ActualValue,
		
		[scriptblock]
		$TestScript,
		
		[switch]
		$Negate
	)
	end
	{
		foreach ($value in $ActualValue)
		{
			$variables = [System.Collections.Generic.List[psvariable]](
				[psvariable]::new('_', $value))
			
			$succeeded = $TestScript.InvokeWithContext(
                <# functionsToDefine: #>				@{ },
                <# variablesToDefine: #>				$variables,
                <# args:              #>				$value)
			
			if ($Negate.IsPresent)
			{
				$succeeded = -not $succeeded
			}
			
			if (-not $succeeded)
			{
				break
			}
		}
		
		if ($Negate.IsPresent)
		{
			$failureMessage =
			'Expected: All values to fail the evaluation script, ' +
			'but value "{0}" returned true.' -f $value
		}
		else
		{
			$failureMessage =
			'Expected: All values to pass the evaluation script, ' +
			'but value "{0}" returned false.' -f $value
		}
		
		[PSCustomObject]@{
			Succeeded	   = $succeeded
			FailureMessage = $failureMessage
		}
	}
}
Add-ShouldOperator -Name BeTrueForAll -Test $function:BeTrueForAll -Alias All -SupportsArrayInput