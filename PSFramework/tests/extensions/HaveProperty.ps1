function HaveProperty
{
	[CmdletBinding()]
	param (
		$ActualValue,
		
		[string]
		$PropertyName,
		
		$WithValue,
		
		[switch]
		$Negate
	)
	end
	{
		$shouldTestValue = $PSBoundParameters.ContainsKey('WithValue')
		if ($null -eq $ActualValue)
		{
			if ($shouldTestValue)
			{
				if ($Negate.IsPresent)
				{
					$failureMessage = 'Expected: value "{0}" to contain the property "{1}" where the value was not "{2}" but the input object was null.' -f $ActualValue, $PropertyName, $WithValue
				}
				else
				{
					$failureMessage = 'Expected: value "{0}" to contain the property "{1}" where the value was "{2}" but the input object was null.' -f $ActualValue, $PropertyName, $WithValue
				}
			}
			else
			{
				if ($Negate.IsPresent)
				{
					$failureMessage = 'Expected: value "{0}" to not contain the property "{1}" but the input object was null.' -f $ActualValue, $PropertyName
				}
				else
				{
					$failureMessage = 'Expected: value "{0}" to contain the property "{1}" but the input object was null.' -f $ActualValue, $PropertyName
				}
			}
			
			return [PSCustomObject]@{
				Succeeded	   = $false
				FailureMessage = $failureMessage
			}
		}
		
		$property = $ActualValue.psobject.Properties[$PropertyName]
		$hasProperty = [bool]$property
		if (-not $shouldTestValue)
		{
			$succeeded = $hasProperty
			if ($Negate.IsPresent)
			{
				$succeeded = -not $succeeded
			}
			
			if (-not $succeeded)
			{
				if ($Negate.IsPresent)
				{
					$failureMessage = 'Expected: value "{0}" to not contain the property "{1}" but it did.' -f $ActualValue, $PropertyName
				}
				else
				{
					$failureMessage = 'Expected: value "{0}" to contain the property "{1}" but it did not.' -f $ActualValue, $PropertyName
				}
			}
			
			return [PSCustomObject]@{
				Succeeded	   = $succeeded
				FailureMessage = $failureMessage
			}
		}
		
		if (-not $hasProperty)
		{
			if ($Negate.IsPresent)
			{
				$failureMessage = 'Expected: value "{0}" to contain the property "{1}" where the value was not "{2}" but the property did not exist.' -f $ActualValue, $PropertyName, $WithValue
			}
			else
			{
				$failureMessage = 'Expected: value "{0}" to contain the property "{1}" where the value was "{2}" but the property did not exist.' -f $ActualValue, $PropertyName, $WithValue
			}
			
			return [PSCustomObject]@{
				Succeeded	   = $false
				FailureMessage = $failureMessage
			}
		}
		
		$succeeded = $WithValue -eq $property.Value
		if ($Negate.IsPresent)
		{
			$succeeded = -not $succeeded
			$failureMessage = 'Expected: value "{0}" to contain the property "{1}" where the value was not "{2}" but it was.' -f $ActualValue, $PropertyName, $WithValue
		}
		else
		{
			$failureMessage = 'Expected: value "{0}" to contain the property "{1}" where the value was not "{2}" but the actual value was "{3}".' -f $ActualValue, $PropertyName, $WithValue, $property.Value
		}
		
		[PSCustomObject]@{
			Succeeded	   = $succeeded
			FailureMessage = $failureMessage
		}
	}
}
Add-ShouldOperator -Name HaveProperty -Test $function:HaveProperty