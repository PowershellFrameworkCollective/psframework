function Start-PSFRunspaceWorkflow {
	<#
	.SYNOPSIS
		Starts a Runspace Workflow.
	
	.DESCRIPTION
		Starts a Runspace Workflow.
		This will launch all workers and their associated runspaces.

		Consider queuing input first (Write-PSFRunspaceQueue) before starting the workflow.
	
	.PARAMETER Name
		Name of the Runspace Workflow to launch.
	
	.PARAMETER InputObject
		Runspace Workflow object to launch.
	
	.EXAMPLE
		PS C:\> Start-PSFRunspaceWorkflow -Name MailboxAnalysis

		Starts the Runspace Workflow "MailboxAnalysis"

	.EXAMPLE
		PS C:\> Get-PSFRunspaceWorkflow | Start-PSFRunspaceWorkflow

		Start all Runspace Worklflow.
	
	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>
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
			$resolvedWorkflow.Start()
		}
	}
}