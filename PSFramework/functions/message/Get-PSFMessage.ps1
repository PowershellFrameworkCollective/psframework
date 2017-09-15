function Get-PSFMessage
{
<#
	.SYNOPSIS
		Returns log entries for the PSFramework
	
	.DESCRIPTION
		Returns log entries for the PSFramework. Handy when debugging or developing a script using it.
	
	.PARAMETER Errors
		Instead of log entries, the error entries will be retrieved
	
	.EXAMPLE
		Get-PSFMessage
		
		Returns all log entries currently in memory.
#>
	[CmdletBinding()]
	param
	(
		[switch]
		$Errors
	)
	
	BEGIN
	{
		
	}
	
	PROCESS
	{
		if ($Errors) { return [PSFramework.Message.LogHost]::GetErrors() }
		else { return [PSFramework.Message.LogHost]::GetLog() }
	}
	
	END
	{
		
	}
}