function Disable-PSFTaskEngineTask
{
<#
	.SYNOPSIS
		Disables a task registered to the PSFramework task engine.
	
	.DESCRIPTION
		Disables a task registered to the PSFramework task engine.
	
	.PARAMETER Name
		Name of the task to disable.
	
	.PARAMETER Task
		The task registered. Must be a task object returned by Get-PSFTaskEngineTask.
	
	.EXAMPLE
		PS C:\> Get-PSFTaskEngineTask -Name 'mymodule.maintenance' | Disable-PSFTaskEngineTask
		
		Disables the task named 'mymodule.maintenance'
#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Disable-PSFTaskEngineTask')]
	param (
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.TaskEngine.PsfTask[]]
		$Task
	)
	
	process
	{
		foreach ($item in $Task)
		{
			if ($item.Enabled)
			{
				Write-PSFMessage -Level Verbose -String 'Disable-PSFTaskEngineTask.Disabling' -StringValues $item.Name -Tag 'disable', 'taskengine', 'task'
				$item.Enabled = $false
			}
		}
		foreach ($taskName in $Name)
		{
			foreach ($taskObject in Get-PSFTaskEngineTask -Name $taskName)
			{
				Write-PSFMessage -Level Verbose -String 'Disable-PSFTaskEngineTask.Disabling' -StringValues $taskObject.Name -Tag 'disable', 'taskengine', 'task'
				$taskObject.Enabled = $false
			}
		}
	}
}