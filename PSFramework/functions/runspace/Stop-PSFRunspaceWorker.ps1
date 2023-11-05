function Stop-PSFRunspaceWorker {
	<#
	.SYNOPSIS
		Stops a specific runspace worker, part of a Runspace Workflow.
	
	.DESCRIPTION
		Stops a specific runspace worker, part of a Runspace Workflow.
		This ends all associated runspaces, but does not affect any queue content.
	
	.PARAMETER InputObject
		The Worker object to stop.
	
	.EXAMPLE
		PS C:\> $worker | Stop-PSFRunspaceWorker

		Stops the worker object in $worker.
	
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
			$item.Stop()
		}
	}
}