function Remove-PSFRunspaceWorkflow {
	<#
	.SYNOPSIS
		Removes a Runspace Workflow, stopping all processing.
	
	.DESCRIPTION
		Removes a Runspace Workflow, stopping all processing.
		This stops all workers, ends all runspaces and unlists the workflow object.

		The queues remain untouched, but will be garbage collected together with the workflow object,
		assuming no variable outside of the module retains it.
	
	.PARAMETER Name
		The name of the Runspace Workflow to remove.
	
	.EXAMPLE
		PS C:\> Get-PSFRunspaceWorkflow | Remove-PSFRunspaceWorkflow

		Stops and removes all runspace workflows.
	
	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html

	.LINK
		Get-PSFRunspaceWorkflow

	.LINK
		New-PSFRunspaceWorkflow
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfArgumentCompleter('PSFramework-runspace-workflow-name')]
		[string[]]
		$Name
	)
	process {
		foreach ($entry in $Name) {
			if (-not $script:runspaceWorkflows[$entry]) { continue }
			$script:runspaceWorkflows[$entry].Stop()
			$script:runspaceWorkflows.Remove($entry)
		}
	}
}