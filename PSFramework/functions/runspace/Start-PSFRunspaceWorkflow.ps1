﻿function Start-PSFRunspaceWorkflow {
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

	.PARAMETER PassThru
		Return the runspace workflow just started.
	
	.EXAMPLE
		PS C:\> Start-PSFRunspaceWorkflow -Name MailboxAnalysis

		Starts the Runspace Workflow "MailboxAnalysis"

	.EXAMPLE
		PS C:\> Get-PSFRunspaceWorkflow | Start-PSFRunspaceWorkflow

		Start all Runspace Worklflow.
	
	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('PSFramework-runspace-workflow-name')]
		[string[]]
		$Name,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSWorkflow[]]
		$InputObject,

		[switch]
		$PassThru
	)
	process {
		$resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $Name -InputObject $InputObject -Cmdlet $PSCmdlet

		foreach ($resolvedWorkflow in $resolvedWorkflows) {
			$resolvedWorkflow.Start()
			if ($PassThru) { $resolvedWorkflow }
		}
	}
}