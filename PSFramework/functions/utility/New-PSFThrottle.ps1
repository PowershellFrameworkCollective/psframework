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
	
	.PARAMETER Limit
		The number of valid executions within the specified interval.
	
	.EXAMPLE
		PS C:\> New-PSFThrottle -Interval 1m -Limit 60
	
		Generates a throttle object that will allow 60 slots/executions every minute.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSFTimeSpan]
		$Interval,
		
		[Parameter(Mandatory = $true)]
		[int]
		$Limit
	)
	
	process {
		New-Object PSFramework.Utility.Throttle($Limit, $Interval)
	}
}