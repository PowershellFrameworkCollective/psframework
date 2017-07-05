function Clear-PSFResultCache
{
	<#
		.SYNOPSIS
			Clears the result cache
		
		.DESCRIPTION
			Clears the result cache, which can come in handy if you have a huge amount of data stored within and want to free the memory.
		
		.EXAMPLE
			PS C:\> Clear-PSFResultCache
	
			Clears the result cache, freeing up any used memory.
	#>	
	[CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess = $true)]
	param (
		
	)
	
	if ($pscmdlet.ShouldProcess("Result cache", "Clearing the result cache"))
	{
		[PSFramework.ResultCache.ResultCache]::Clear()
	}
}