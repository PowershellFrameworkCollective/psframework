function Write-PSFRunspaceQueue {
	<#
	.SYNOPSIS
		Write data to a queue of a Runspace Workflow.
	
	.DESCRIPTION
		Write data to a queue of a Runspace Workflow.
		This is generally used to provide the initial input of the first queue.

		Can also be used by a worker code to provide output to more than one queue.
	
	.PARAMETER Name
		Name of the Queue to write to.
	
	.PARAMETER Value
		The value to write.

	.PARAMETER BulkValues
		Write multiple values as separate entries.

	.PARAMETER Close
		Closes the queue after writing the input.
		This prevents further data to be added to the queue,
		and allows a worker to know, when it has fully processed input.

	.PARAMETER WorkflowName
		Name of the workflow owning the queue written to.
	
	.PARAMETER InputObject
		Workflow object that owns the queue written to.
	
	.EXAMPLE
		PS C:\> $workflow | Write-PSFRunspaceQueue -Name input -BulkValues $entries

		Provides all values in $entries as input for the queue named "input" of the Runspace Workflow in $workflow.
	
	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
	[CmdletBinding(DefaultParameterSetName = 'Single')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Single')]
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'SingleCurrent')]
		[AllowNull()]
		$Value,

		[Parameter(Mandatory = $true, ParameterSetName = 'Multi')]
		[AllowNull()]
		[object[]]
		$BulkValues,

		[Parameter(Mandatory = $true, ParameterSetName = 'SingleCurrent')]
		[switch]
		$UseCurrent,

		[switch]
		$Close,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Single')]
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Multi')]
		[PsfArgumentCompleter('PSFramework-runspace-workflow-name')]
		[string[]]
		$WorkflowName,

		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Single')]
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Multi')]
		[PSFramework.Runspace.RSWorkflow[]]
		$InputObject
	)
	process {
		$resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $WorkflowName -InputObject $InputObject -Cmdlet $PSCmdlet -Terminate -CurrentWorker
		foreach ($resolvedWorkflow in $resolvedWorkflows) {
			$values = $BulkValues
			if ($PSBoundParameters.Keys -contains 'Value') {
				$values = $Value
			}
			foreach ($item in $values) {
				$resolvedWorkflow.Queues.$Name.Enqueue($item)
				if ($global:__PSF_Worker -and $Name -eq $global:__PSF_Worker.OutQueue) {
					$global:__PSF_Worker.IncrementOutput()
				}
			}
			if ($Close) { $resolvedWorkflow.CloseQueue($Name) }
		}
	}
}