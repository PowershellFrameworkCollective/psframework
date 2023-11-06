@{
	'Add-PSFRunspaceWorker.Error.UntrustedFunctionCode'      = 'Failed to load function {0}: String-based code is not trusted in a secured console. Provide its code as a scriptblock, rather than a string to enable code trust verification.' # $pair.Key
	'Add-PSFRunspaceWorker.Error.UntrustedTextFunction'      = 'Failed to load function {0}: The provided function code is not trusted (in Constrained language Mode) and cannot be imported. Ensure the code building the scriptblock is trusted to create a non-constrained scriptblock.' # $pair.Key

	'New-PSFRunspaceWorkflow.Error.ExistsAlready'            = 'Failed to create workflow {0}: It already exists! Use "-Force" to overwrite the existing Runspace Workflow, interrupting all currently ongoing processing.' # $Name

	'Read-PSFRunspaceQueue.Error.Continual.TooManyWorkflows' = 'Error resolving queue to read from in continuous mode: {0}. Multiple workflows found, while continuous read only supports a single workflow. Workflows found: {1}' # $Name, ($resolvedWorkflows.Name -join ', ')

	'Register-PSFRunspace.Runspace.Updating'                 = "Updating runspace: <c='em'>{0}</c>" # ($Name)
	'Register-PSFRunspace.Runspace.Creating'                 = "Registering runspace: <c='em'>{0}</c>" # ($Name)

	'Resolve-PsfRunspaceWorkflow.Error.NoInput'              = 'No Runspace Workflow was provided! Provide either name or object.' #
	'Resolve-PsfRunspaceWorkflow.Error.NotFound'             = 'No Runspace Workflow found under the specified name(s): {0}' # ($Name -join ', ')
	
	'Start-PSFRunspace.Starting'                             = "Starting runspace: <c='em'>{0}</c>" # ($item)
	'Start-PSFRunspace.Starting.Failed'                      = "Failed to start runspace: <c='em'>{0}</c>" # ($item)
	'Start-PSFRunspace.UnknownRunspace'                      = "Failed to start runspace: <c='em'>{0}</c> | No runspace registered under this name!" # ($item)
	
	'Stop-PSFRunspace.Stopping'                              = "Stopping runspace: <c='em'>{0}</c>" # ($item)
	'Stop-PSFRunspace.Stopping.Failed'                       = "Failed to stop runspace: <c='em'>{0}</c>" # ($item)
	'Stop-PSFRunspace.UnknownRunspace'                       = "Failed to stop runspace: <c='em'>{0}</c> | No runspace registered under this name!" # ($item)

	'Wait-PSFRunspaceWorkflow.Error.Timeout'                 = 'Timeout ({0:HH:mm:ss}) reached waiting for Runspace Workflow "{1}" to complete' # $limit, $resolvedWorkflow.Name
}