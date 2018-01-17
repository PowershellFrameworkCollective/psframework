function Clear-PSFResultCache
{
	<#
		.SYNOPSIS
			Clears the result cache
		
		.DESCRIPTION
			Clears the result cache, which can come in handy if you have a huge amount of data stored within and want to free the memory.
	
		.PARAMETER Confirm
			If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
		.PARAMETER WhatIf
			If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
		
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