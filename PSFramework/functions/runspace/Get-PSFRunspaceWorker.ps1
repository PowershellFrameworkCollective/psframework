function Get-PSFRunspaceWorker {
	<#
	.SYNOPSIS
		Retrieve workers associated with a Runspace Dispatcher.
	
	.DESCRIPTION
		Retrieve workers associated with a Runspace Dispatcher.
	
	.PARAMETER Name
		Name of the worker to filter by.
		Defaults to *
	
	.PARAMETER DispatcherName
		Name of the Runspace Dispatcher from which to retrieve workers.
		The dispatcher contains all the workers, queues and management tools for the Runspace Workload.
	
	.PARAMETER InputObject
		Dispatcher object of the Runspace Dispatcher from which to retrieve workers.
		The dispatcher contains all the workers, queues and management tools for the Runspace Workload.
	
	.EXAMPLE
		PS C:\> Get-PSFRunspaceDispatcher | Get-PSFRunspaceWorker

		Get all workers of all runspace dispatchers.

	.LINK
		TODO: Add link to section
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name = '*',

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$DispatcherName,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject
	)
	process {
		$resolvedDispatchers = Resolve-PsfRunspaceDispatcher -Name $DispatcherName -InputObject $InputObject -Cmdlet $PSCmdlet

		$resolvedDispatchers.Workers.Values | Where-Object Name -Like $Name
	}
}