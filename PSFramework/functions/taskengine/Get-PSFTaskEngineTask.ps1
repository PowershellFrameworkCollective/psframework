function Get-PSFTaskEngineTask
{
	<#
		.SYNOPSIS
			Returns tasks registered for the task engine
		
		.DESCRIPTION
			Returns tasks registered for the task engine
		
		.PARAMETER Name
			Default: "*"
			Only tasks with similar names are returned.
		
		.EXAMPLE
			PS C:\> Get-PSFTaskEngineTask
	
			Returns all tasks registered to the task engine
	
		.EXAMPLE
			PS C:\> Get-PSFTaskEngineTask -Name 'mymodule.*'
	
			Returns all tasks registered to the task engine whose name starts with 'mymodule.'
			(It stands to reason that only tasks belonging to the module 'mymodule' would be returned that way)
	#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFTaskEngineTask')]
	Param (
		[string]
		$Name = "*"
	)
	
	process
	{
		[PSFramework.TaskEngine.TaskHost]::Tasks.Values | Where-Object Name -Like $Name
	}
}