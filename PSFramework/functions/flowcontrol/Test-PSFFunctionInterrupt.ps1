﻿function Test-PSFFunctionInterrupt
{
    <#
        .SYNOPSIS
            Tests whether the calling function should be interrupted.
        
        .DESCRIPTION
            This helper function is designed to work in tandem with Stop-PSFFunction.
            When gracefully terminating a function, there is a major issue:
            "Return" will only stop the current one of the three blocks (Begin, Process, End).
            All other statements have side effects or produce lots of red text.
    
            So, Stop-PSFFunction writes a variable into the parent scope, that signals the function should cease.
            This function then checks for that very variable and returns true if it is set.
    
            This avoids having to handle odd variables in the parent function and causes the least impact on contributors.
	
			For a more detailed explanation - including commented full-scale implementation examples - see the associated help article:
			Get-Help about_psf_flowcontrol
        
        .EXAMPLE
            if (Test-PSFFunctionInterrupt) { return }
    
            The calling function will stop if this function returns true.
    #>
	[OutputType([System.Boolean])]
	[CmdletBinding()]
	Param (
		
	)
	
	$var = Get-Variable -Name "__psframework_interrupt_function_6e4%ö%qÖ%D72TgÜ9I90zÄ0N9äE6&§l§cnÖ12ßüäp4Z&5l37Gcs§Ö245iÄßlSfk6VdNTR6&00j43Ä§Ä7öÄüW0M5uüßE0bea8vÜ1Ä%" -Scope 1 -ErrorAction Ignore
	if ($var.Value) { return $true }
	return $false
}