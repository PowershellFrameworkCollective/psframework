function Test-PSFTaskEngineTask
{
	<#
		.SYNOPSIS
			Tests, whether the specified task has already been executed.
		
		.DESCRIPTION
			Tests, whether the specified task has already been executed.
			Returns false, if the task doesn't exist.
		
		.PARAMETER Name
			Name of the task to test
		
		.EXAMPLE
			PS C:\> Test-PSFTaskEngineTask -Name 'mymodule.maintenance'
	
			Returns, whether the task named 'mymodule.maintenance' has already been executed at least once.
	#>
	[OutputType([System.Boolean])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFTaskEngineTask')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name
	)
	
	New-Variable -Name task -Scope Private -Force
	if (-not ([PSFramework.TaskEngine.TaskHost]::Tasks.TryGetValue($Name, [ref]$task)))
	{
		return $false
	}
	
	$task.LastExecution -gt $task.Registered
}