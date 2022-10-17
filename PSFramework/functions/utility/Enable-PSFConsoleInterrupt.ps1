function Enable-PSFConsoleInterrupt {
	<#
	.SYNOPSIS
		Re-enables the use of CTRL+C to interrupt the console.
	
	.DESCRIPTION
		Re-enables the use of CTRL+C to interrupt the console.
	
	.EXAMPLE
		PS C:\> Enable-PSFConsoleInterrupt
		
		Re-enables the use of CTRL+C to interrupt the console.
	#>
	[CmdletBinding()]
	param ()

	[Console]::TreatControlCAsInput = $false
}