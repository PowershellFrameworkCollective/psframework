function New-PSFThrottle {
<#
	.SYNOPSIS
		Create a throttle object, used to not exceed a certain rate of executions per time interval.
	
	.DESCRIPTION
		Create a throttle object, used to not exceed a certain rate of executions per time interval.
		Use this to limit the rate at which you contact throttled APIs / Service Connections.
	
		The returnd object has a GetSlot() method, which will return immediately if slots are available.
		If none are, it will wait to return until there are.
	
		This object is threadsafe and can be used from multiple runspaces.
		However, it is not guaranteed to be 100% precise with concurrent access, possibly allowing (slight) overbooking.
	
	.PARAMETER Interval
		The time range during which we measure slot/execution limits.
		Can be either a timespan or a human-friendly notation such as "10m" for 10 minutes or "1h" for one hour.
	
	.PARAMETER Limit
		The number of valid executions within the specified interval.

	.PARAMETER ExtraLimits
		Additional Interval/Limit pairs to throttle over at the same time.
		This allows logic such as "Not more than 10 per minute and 100 per hour".
		The keys of the hashtable are the interval (same type as the Interval parameter), the values the limit (int)
	
	.EXAMPLE
		PS C:\> New-PSFThrottle -Interval 1m -Limit 60
	
		Generates a throttle object that will allow 60 slots/executions every minute.

	.EXAMPLE
		PS C:\> New-PSFThrottle -Interval 1m -Limit 60 -ExtraLimits @{ '1h' = 600 }

		Generates a throttle object that will allow 60 slots/executions every minute and 600 every hour.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSFTimeSpan]
		$Interval,
		
		[Parameter(Mandatory = $true)]
		[int]
		$Limit,

		[hashtable]
		$ExtraLimits = @{}
	)
	
	process {
		$throttle = New-Object PSFramework.Utility.Throttle($Limit, $Interval)
		foreach ($pair in $ExtraLimits.GetEnumerator()) {
			try { $throttle.AddLimit($pair.Key, $pair.Value) }
			catch { Write-PSFMessage -Level Error -String 'New-PSFThrottle.Error.InvalidLimit' -StringValues $pair.Key, $pair.Value -ErrorRecord $_ -EnableException $true -PSCmdlet $PSCmdlet }
		}
		$throttle
	}
}