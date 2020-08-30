function Register-PSFTaskEngineTask
{
	<#
		.SYNOPSIS
			Allows scheduling PowerShell tasks, that are perfomed in the background.
		
		.DESCRIPTION
			Allows scheduling PowerShell tasks, that are perfomed in the background.
	
			All scriptblocks scheduled like this will be performed on a separate runspace.
			None of the scriptblocks will affect the main session (so you cannot manipulate variables, etc.)
	
			This system is designed for two use-cases:
			- Reducing module import time by off-loading expensive one-time actions (such as building a cache) in the background
			- Scheduling periodic script executions that should occur while the process is running (e.g.: continuous maintenance, cache updates, ...)
	
			It also avoids overloading the client computer by executing too many tasks at the same time, as multiple modules running code in the background might.
			Instead tasks that are due simultaneously are processed by priority.
		
		.PARAMETER Name
			The name of the task.
			Must be unique, otherwise it will update the existing task.
	
		.PARAMETER Description
			Description of the task.
			Helps documenting the task and what it is supposed to be doing.
		
		.PARAMETER ScriptBlock
			The task/scriptblock that should be performed as a background task.
		
		.PARAMETER Once
			Whether the task should be performed only once.
		
		.PARAMETER Interval
			The interval at which the task should be repeated.
		
		.PARAMETER Delay
			How far after the initial registration should the task script wait before processing this.
			This can be used to delay background stuff that should not content with items that would be good to have as part of the module import.
		
		.PARAMETER Priority
			How important is this task?
			If multiple tasks are due at the same maintenance cycle, the more critical one will be processed first.
	
		.PARAMETER ResetTask
			If the task already exists, it will be reset by setting this parameter (this switch is ignored when creating new tasks).
			This allows explicitly registering tasks for re-execution, even though they were set to execute once only.
		
		.PARAMETER EnableException
			This parameters disables user-friendly warnings and enables the throwing of exceptions.
			This is less user friendly, but allows catching exceptions in calling scripts.
		
		.EXAMPLE
			PS C:\> Register-PSFTaskEngineTask -Name 'mymodule.buildcache' -ScriptBlock $ScriptBlock -Once -Description 'Builds the object cache used by the mymodule module'
	
			Registers the task contained in $ScriptBlock under the name 'mymodule.buildcache' to execute once at the system's earliest convenience in a medium (default) priority.
	
		.EXAMPLE
			PS C:\> Register-PSFTaskEngineTask -Name 'mymodule.maintenance' -ScriptBlock $ScriptBlock -Interval "00:05:00" -Delay "00:01:00" -Priority Critical -Description 'Performs critical system maintenance in order for the mymodule module to function'
	
			Registers the task contained in $ScriptBlock under the name 'mymodule.maintenance'
			- Sets it to execute every 5 minutes
			- Sets it to wait for 1 minute after registration before starting the first execution
			- Sets it to priority "Critical", ensuring it takes precedence over most other tasks.
	#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFTaskEngineTask')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[string]
		$Description,
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$ScriptBlock,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Once")]
		[switch]
		$Once,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Repeating")]
		[PsfValidateScript('PSFramework.Validate.TimeSpan.Positive', ErrorString = 'PSFramework.Validate.TimeSpan.Positive')]
		[PSFTimeSpan]
		$Interval,
		
		[PSFTimeSpan]
		$Delay,
		
		[PSFramework.TaskEngine.Priority]
		$Priority = "Medium",
		
		[switch]
		$ResetTask,
		
		[switch]
		$EnableException
	)
	
	process
	{
		
		#region Case: Task already registered
		if ([PSFramework.TaskEngine.TaskHost]::Tasks.ContainsKey($Name))
		{
			$task = [PSFramework.TaskEngine.TaskHost]::Tasks[$Name]
			if (Test-PSFParameterBinding -ParameterName Description) { $task.Description = $Description }
			if ($task.ScriptBlock -ne $ScriptBlock) { $task.ScriptBlock = $ScriptBlock }
			if (Test-PSFParameterBinding -ParameterName Once) { $task.Once = $Once }
			if (Test-PSFParameterBinding -ParameterName Interval)
			{
				$task.Once = $false
				$task.Interval = $Interval
			}
			if (Test-PSFParameterBinding -ParameterName Delay) { $task.Delay = $Delay }
			if (Test-PSFParameterBinding -ParameterName Priority) { $task.Priority = $Priority }
			
			if ($ResetTask)
			{
				$task.Registered = Get-Date
				$task.LastExecution = New-Object System.DateTime(0)
				$task.State = 'Pending'
			}
		}
		#endregion Case: Task already registered
		
		#region New Task
		else
		{
			$task = New-Object PSFramework.TaskEngine.PsfTask
			$task.Name = $Name
			if (Test-PSFParameterBinding -ParameterName Description) { $task.Description = $Description }
			$task.ScriptBlock = $ScriptBlock
			if (Test-PSFParameterBinding -ParameterName Once) { $task.Once = $true }
			if (Test-PSFParameterBinding -ParameterName Interval) { $task.Interval = $Interval }
			if (Test-PSFParameterBinding -ParameterName Delay) { $task.Delay = $Delay }
			$task.Priority = $Priority
			$task.Registered = Get-Date
			[PSFramework.TaskEngine.TaskHost]::Tasks[$Name] = $task
		}
		#endregion New Task
	}
	end { Start-PSFRunspace -Name "psframework.taskengine" -EnableException:$EnableException }
}