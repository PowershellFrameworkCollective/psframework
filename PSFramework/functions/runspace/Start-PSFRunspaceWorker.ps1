function Start-PSFRunspaceWorker {
	<#
	.SYNOPSIS
		Start a runspace worker, part of the logic executing a Runspace Workflow.
	
	.DESCRIPTION
		Start a runspace worker, part of the logic executing a Runspace Workflow.
		This will have it start its workers and process any queued input.

		Use this to start only part of a Runspace Workflow, rather than all of it.
	
	.PARAMETER InputObject
		The Worker object to start.
	
	.EXAMPLE
		PS C:\> $worker | Start-PSFRunspaceWorker

		Starts the worker specified in $worker
	
	.LINK
		TODO: Add link to section
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSWorker[]]
		$InputObject
	)
	process {
		foreach ($item in $InputObject) {
			$item.Start()
		}
	}
}