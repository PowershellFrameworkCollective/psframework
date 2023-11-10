function Get-PSFRunspaceWorker {
	<#
	.SYNOPSIS
		Retrieve workers associated with a Runspace Workflow.
	
	.DESCRIPTION
		Retrieve workers associated with a Runspace Workflow.
	
	.PARAMETER Name
		Name of the worker to filter by.
		Defaults to *
	
	.PARAMETER WorkflowName
		Name of the Runspace Workflow from which to retrieve workers.
		The workflow contains all the workers, queues and management tools for the Runspace Workflow.
	
	.PARAMETER InputObject
		Workflow object from which to retrieve workers.
		The workflow contains all the workers, queues and management tools for the Runspace Workflow.
	
	.EXAMPLE
		PS C:\> Get-PSFRunspaceWorkflow | Get-PSFRunspaceWorker

		Get all workers of all runspace workflows.

	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name = '*',

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('PSFramework-runspace-workflow-name')]
		[string[]]
		$WorkflowName,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSWorkflow[]]
		$InputObject
	)
	process {
		$resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $WorkflowName -InputObject $InputObject -Cmdlet $PSCmdlet

		$resolvedWorkflows.Workers.Values | Where-Object Name -Like $Name
	}
}