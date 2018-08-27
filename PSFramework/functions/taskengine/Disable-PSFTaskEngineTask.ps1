function Disable-PSFTaskEngineTask
{
	<#
		.SYNOPSIS
			Disables a task registered to the PSFramework task engine.
		
		.DESCRIPTION
			Disables a task registered to the PSFramework task engine.
		
		.PARAMETER Task
			The task registered. Must be a task object returned by Get-PSFTaskEngineTask.
		
		.EXAMPLE
			PS C:\> Get-PSFTaskEngineTask -Name 'mymodule.maintenance' | Disable-PSFTaskEngineTask
	
			Disables the task named 'mymodule.maintenance'
	#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Disable-PSFTaskEngineTask')]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[PSFramework.TaskEngine.PsfTask[]]
		$Task
	)
	
	process
	{
		foreach ($item in $Task)
		{
			if ($item.Enabled)
			{
				Write-PSFMessage -Level Verbose -Message "Disabling task engine task: $($item.Name)" -Tag 'disable', 'taskengine', 'task'
				$item.Enabled = $false
			}
		}
	}
}