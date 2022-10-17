function Disable-PSFConsoleInterrupt {
	<#
	.SYNOPSIS
		Prevents the use of CTRL+C from interrupting the console.
	
	.DESCRIPTION
		Prevents the use of CTRL+C from interrupting the console.

		Use this to prevent manual interruption of critical tasks, but do not forget to re-enable it as soon as possible.
		Usually, ctrl+C is a critical part of the user experience, enabling the user to interrupt the console
		and avoid a hang from locking the console.
	
	.EXAMPLE
		PS C:\> Disable-PSFConsoleInterrupt
		
		Prevents the use of CTRL+C from interrupting the console.
	#>
	[CmdletBinding()]
	param ()

	[Console]::TreatControlCAsInput = $true
}