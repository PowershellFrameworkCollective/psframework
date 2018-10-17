function Test-PSFFunctionInterrupt
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
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFFunctionInterrupt')]
	Param (
		
	)
	
	$psframework_killqueue -contains (Get-PSCallStack)[1].InvocationInfo.GetHashCode()
}