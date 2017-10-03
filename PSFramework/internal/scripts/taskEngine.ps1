$scriptBlock = {
	$script:___ScriptName = 'psframework.taskengine'
	
	try
	{
		#region Main Execution
		while ($true)
		{
			# This portion is critical to gracefully closing the script
			if ([PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLower()].State -notlike "Running")
			{
				break
			}
			
			$task = $null
			$tasksDone = @()
			while ($task = [PSFramework.TaskEngine.TaskHost]::GetNextTask($tasksDone))
			{
				try { ([ScriptBlock]::Create($task.ScriptBlock.ToString())).Invoke() }
				catch { Write-PSFMessage -EnableException $false -Level Warning -Message "[Maintenance] Task '$($task.Name)' failed to execute: $_" -ErrorRecord $_ -FunctionName "task:TaskEngine" -Target $task }
				$task.LastExecution = Get-Date
				$tasksDone += $task.Name
			}
			
			# If there will no more tasks need executing in the future, might as well kill the runspace
			if (-not ([PSFramework.TaskEngine.TaskHost]::HasPendingTasks)) { break }
			
			Start-Sleep -Seconds 5
		}
		#endregion Main Execution
	}
	catch {  }
	finally
	{
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLower()].SignalStopped()
	}
}

Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'psframework.taskengine'