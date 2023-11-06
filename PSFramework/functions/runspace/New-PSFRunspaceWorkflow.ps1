function New-PSFRunspaceWorkflow {
	<#
	.SYNOPSIS
		Creates a new runspace workflow.
	
	.DESCRIPTION
		Creates a new runspace workflow.
		The workflow object is the core element of the runspace workflow system.

		It contains the workers, runspaces and queues that execute the workflow.
		All workflows are stored centrally and cen be retrieved using Get-PSFRunspaceWorkflow.
		To ensure proper cleanup, remember to use Remove-PSFRunspaceWorkflow when completed.
	
	.PARAMETER Name
		The name of the workflow to create.
		Must be unique in the current runspace.
	
	.PARAMETER Force
		Allows overwriting an existing workflow of the same name.
		Note: Doing so will terminate all processing on the previous workflow.
	
	.EXAMPLE
		PS C:\> New-PSFRunspaceWorkflow -Name 'MyModule.MyWorkflow
		
		Creates a new Runspace Workflow with the name 'MyModule.MyWorkflow'

	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html

	.LINK
		Get-PSFRunspaceWorkflow

	.LINK
		Remove-PSFRunspaceWorkflow
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[OutputType([PSFramework.Runspace.RSWorkflow])]
	[CmdletBinding()]
	param (
		[string]
		$Name,

		[switch]
		$Force
	)
	process {
		if ($script:runspaceWorkflows[$Name]) {
			if (-not $Force) {
				Stop-PSFFunction -String 'New-PSFRunspaceWorkflow.Error.ExistsAlready' -StringValues $Name -EnableException $true -Cmdlet $PSCmdlet
			}

			$script:runspaceWorkflows[$Name].Stop()
		}

		$script:runspaceWorkflows[$Name] = [PSFramework.Runspace.RSWorkflow]::new($Name)
		$script:runspaceWorkflows[$Name]
	}
}