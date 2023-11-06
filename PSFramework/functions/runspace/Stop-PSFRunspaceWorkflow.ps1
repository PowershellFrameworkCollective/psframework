function Stop-PSFRunspaceWorkflow {
	<#
	.SYNOPSIS
		Stop a running Runspace Workflow.
	
	.DESCRIPTION
		Stop a running Runspace Workflow.
		This shuts down all running runspaces of all associated workers.
		Queues will remain unaffected, and the Workflow remains registered and available.

		To fully remove it, use Remove-PSFRunspaceWorkflow instead.
	
	.PARAMETER Name
		The name of the Runspace Workflow to stop.
	
	.PARAMETER InputObject
		The Runspace Workflow object to stop.
	
	.EXAMPLE
		PS C:\> $workflow | Stop-PSFRunspaceWorkflow

		Stops the specified Runspace Workflow.
	
	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSWorkflow[]]
		$InputObject
	)
	process {
		$resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $Name -InputObject $InputObject -Cmdlet $PSCmdlet

		foreach ($resolvedWorkflow in $resolvedWorkflows) {
			$resolvedWorkflow.Stop()
		}
	}
}