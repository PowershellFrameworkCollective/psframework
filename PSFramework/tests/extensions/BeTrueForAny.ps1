function BeTrueForAny
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
		$succeeded = $false
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
			
			if ($succeeded)
			{
				break
			}
		}
		
		if (-not $succeeded)
		{
			if ($Negate.IsPresent)
			{
				$failureMessage =
				'Expected: Any value to fail the evaluation script, ' +
				'but no value returned false. (ActualValue: {0})' -f ($ActualValue -join ', ')
			}
			else
			{
				$failureMessage =
				'Expected: Any value to pass the evaluation script, ' +
				'but no value returned true. (ActualValue: {0})' -f ($ActualValue -join ', ')
			}
		}
		
		[PSCustomObject]@{
			Succeeded	   = $succeeded
			FailureMessage = $failureMessage
		}
	}
}
Add-ShouldOperator -Name BeTrueForAny -Test $function:BeTrueForAny -Alias Any -SupportsArrayInput