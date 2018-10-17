function Enable-PSFTaskEngineTask
{
	<#
		.SYNOPSIS
			Enables a task registered to the PSFramework task engine.
		
		.DESCRIPTION
			Enables a task registered to the PSFramework task engine.
	
			Note:
			Tasks are enabled by default. Use this function to re-enable a task disabled by Disable-PSFTaskEngineTask.
		
		.PARAMETER Task
			The task registered. Must be a task object returned by Get-PSFTaskEngineTask.
		
		.EXAMPLE
			PS C:\> Get-PSFTaskEngineTask -Name 'mymodule.maintenance' | Enable-PSFTaskEngineTask
	
			Enables the task named 'mymodule.maintenance'
	#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Enable-PSFTaskEngineTask')]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[PSFramework.TaskEngine.PsfTask[]]
		$Task
	)
	
	begin
	{
		$didSomething = $false
	}
	process
	{
		foreach ($item in $Task)
		{
			if (-not $item.Enabled)
			{
				Write-PSFMessage -Level Verbose -Message "Enabling task engine task: $($item.Name)" -Tag 'enable','taskengine','task'
				$item.Enabled = $true
				$didSomething = $true
			}
		}
	}
	end
	{
		# If we enabled any task, start the runspace again, in case it isn't already running (no effect if it is)
		if ($didSomething) { Start-PSFRunspace -Name 'psframework.taskengine' }
	}
}