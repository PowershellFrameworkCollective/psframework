function Resolve-PsfRunspaceWorkflow {
	<#
	.SYNOPSIS
		Resolves, which runspace workflow to use.
	
	.DESCRIPTION
		Resolves, which runspace workflow to use.
		Used in all related commands of the runspace system to uniformly figure out the relevant workflow objects.
		Also to have standardized error handling.
	
	.PARAMETER Name
		Name of the workflow to resolve.
	
	.PARAMETER InputObject
		A workflow object to use.
	
	.PARAMETER Cmdlet
		The $PSCmdlet object of the caller, so we may kill execution in the name of the caller.
	
	.PARAMETER Terminate
		Whether a failure to resolve should be terminating.
	
	.PARAMETER CurrentWorker
		Whether to use the "current" worker.
		This only applies when executing in a worker runspace.
	
	.EXAMPLE
		PS C:\> Resolve-PsfRunspaceWorkflow -Name $WorkflowName -InputObject $InputObject -Cmdlet $PSCmdlet -Terminate -CurrentWorker
		
		Evaluates, which of the currently registered workflows is relevant, based on the input values.
		If no workflow can be resolved, throw a terminating exception.
		If called from within a worker runspace, return the workflow of the worker if both $InputObject and $WorkflowName are null or empty.
	#>
	[OutputType([PSFramework.Runspace.RSWorkflow])]
	[CmdletBinding()]
	param (
		[AllowEmptyCollection()]
		[AllowNull()]
		[string[]]
		$Name,

		[AllowEmptyCollection()]
		[AllowNull()]
		[PSFramework.Runspace.RSWorkflow[]]
		$InputObject,

		$Cmdlet,

		[switch]
		$Terminate,

		[switch]
		$CurrentWorker
	)
	process {
		if (-not ($Name -or $InputObject)) {
			if ($CurrentWorker -and $global:__PSF_Workflow) {
				return $global:__PSF_Workflow
			}

			if ($Terminate) {
				Stop-PSFFunction -String 'Resolve-PsfRunspaceWorkflow.Error.NoInput' -EnableException $true -Cmdlet $Cmdlet -Category ObjectNotFound
			}
			$exception = [System.ArgumentException]::new("Must provide either name or an input object!")
			Write-PSFMessage -Level Error -String 'Stop-PSFRunspaceWorkflow.Error.NoInput' -Exception $exception -EnableException $true -PSCmdlet $Cmdlet
			return
		}

		$list = @()
		foreach ($item in $InputObject) {
			if ($item -in $list) { continue }
			$list += $item
		}

		foreach ($entry in $Name) {
			$workflows = Get-PSFRunspaceWorkflow -Name $entry
			foreach ($item in $workflows) {
				if ($item -in $list) { continue }
				$list += $item
			}
		}

		if (-not $list) {
			if ($Terminate) {
				Stop-PSFFunction -String 'Resolve-PsfRunspaceWorkflow.Error.NotFound' -StringValues ($Name -join ', ') -EnableException $true -Cmdlet $Cmdlet -Category ObjectNotFound
			}
			$exception = [System.ArgumentException]::new("Cannot resolve Runspace Workflow: $($Name -join ', ')")
			Write-PSFMessage -Level Error -String 'Stop-PSFRunspaceWorkflow.Error.NotFound' -Exception $exception -EnableException $true -PSCmdlet $Cmdlet
			return
		}

		$list
	}
}