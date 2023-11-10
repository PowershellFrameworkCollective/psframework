function Get-PSFRunspaceWorkflow {
	<#
	.SYNOPSIS
		Returns a list of registered runspace workflows.
	
	.DESCRIPTION
		Returns a list of registered runspace workflows.
		A Runspace workflow object is the main component managing a PSFramework Runspace Workflow
	
	.PARAMETER Name
		By which name to filter.
		Defaults to *
	
	.EXAMPLE
		PS C:\> Get-PSFRunspaceWorkflow
		
		Returns all registered runspace workflows.

	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('PSFramework-runspace-workflow-name')]
		[string]
		$Name = '*'
	)
	process {
		($script:runspaceWorkflows.Values | Where-Object Name -Like $Name)
	}
}