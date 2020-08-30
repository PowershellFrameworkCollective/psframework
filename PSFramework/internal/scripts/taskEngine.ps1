$scriptBlock = {
	$script:___ScriptName = 'psframework.taskengine'
	
	try
	{
		#region Main Execution
		while ($true)
		{
			# This portion is critical to gracefully closing the script
			if ([PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName].State -notlike "Running")
			{
				break
			}
			
			$task = $null
			$tasksDone = @()
			while ($task = [PSFramework.TaskEngine.TaskHost]::GetNextTask($tasksDone))
			{
				$task.State = 'Running'
				try
				{
					[PSFramework.Utility.UtilityHost]::ImportScriptBlock($task.ScriptBlock)
					$task.ScriptBlock.Invoke()
					$task.State = 'Pending'
				}
				catch
				{
					$task.State = 'Error'
					$task.LastError = $_
					Write-PSFMessage -EnableException $false -Level Warning -Message "[Maintenance] Task '$($task.Name)' failed to execute" -ErrorRecord $_ -FunctionName "task:TaskEngine" -Target $task -ModuleName PSFramework
				}
				$task.LastExecution = Get-Date
				if (-not $task.Pending -and ($task.Status -eq "Pending")) { $task.Status = 'Completed' }
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
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName].SignalStopped()
	}
}

Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'psframework.taskengine' -NoMessage