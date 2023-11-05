function New-PSFRunspaceDispatcher {
	<#
	.SYNOPSIS
		Creates a new runspace workflow dispatcher.
	
	.DESCRIPTION
		Creates a new runspace workflow dispatcher.
		The dispatcher is the core element of the runspace workflow system.

		It contains the workers, runspaces and queues that execute the workflow.
		All dispatchers are stored centrally and cen be retrieved using Get-PSFRunspaceDispatcher.
		To ensure proper cleanup, remember to use Remove-PSFRunspaceDispatcher when completed.
	
	.PARAMETER Name
		The name of the dispatcher.
		Must be unique in the current runspace.
	
	.PARAMETER Force
		Allows overwriting an existing dispatcher of the same name.
		Note: Doing so will terminate all processing on the previous dispatcher.
	
	.EXAMPLE
		PS C:\> New-PSFRunspaceDispatcher -Name 'MyModule.MyWorkflow
		
		Creates a new Runspace Workflow Dispatcher with the name 'MyModule.MyWorkflow'

	.LINK
		TODO: Add link to section

	.LINK
		Get-PSFRunspaceDispatcher

	.LINK
		Remove-PSFRunspaceDispatcher
	#>
	[OutputType([PSFramework.Runspace.RSDispatcher])]
	[CmdletBinding()]
	param (
		[string]
		$Name,

		[switch]
		$Force
	)
	process {
		if ($script:runspaceDispatchers[$Name]) {
			if (-not $Force) {
				Stop-PSFFunction -String 'New-PSFRunspaceDispatcher.Error.ExistsAlready' -StringValues $Name -EnableException $true -Cmdlet $PSCmdlet
			}

			$script:runspaceDispatchers[$Name].Stop()
		}

		$script:runspaceDispatchers[$Name] = [PSFramework.Runspace.RSDispatcher]::new($Name)
		$script:runspaceDispatchers[$Name]
	}
}