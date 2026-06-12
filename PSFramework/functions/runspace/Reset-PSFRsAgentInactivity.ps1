function Reset-PSFRsAgentInactivity {
	<#
	.SYNOPSIS
		Signals the current Runspace Workflow Worker Agent(tm) is active.
	
	.DESCRIPTION
		Signals the current Runspace Workflow Worker Agent is active.
		When called from within the code of a Runspace Workflow - specifically, within the code operated by a Generation 2+ Worker - it signals to the Worker-Agent that the current workload is being processed and is not hanging.

		This is used by Generation 2+ Workers when they are configure for timeout type "Idle", where a timeout is performed based on how long the script code has not shown a sign of activity.
		An alternative way of showing activity is using the Write-PSFMessage command.
	
	.EXAMPLE
		PS C:\> Reset-PSFRsAgentInactivity
		
		Signals the current Runspace Workflow Worker Agent is active.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param ()
	process {
		[PSFramework.Runspace.RunspaceHost]::SignalActive()
	}
}