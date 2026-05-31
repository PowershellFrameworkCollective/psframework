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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding()]
	param ()

	try { [Console]::TreatControlCAsInput = $false } catch {}
}
