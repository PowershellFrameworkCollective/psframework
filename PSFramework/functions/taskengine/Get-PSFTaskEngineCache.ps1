function Get-PSFTaskEngineCache
{
	<#
		.SYNOPSIS
			Retrieve values from the cache for a task engine task.
		
		.DESCRIPTION
			Retrieve values from the cache for a task engine task.
			Tasks scheduled under the PSFramework task engine do not have a way to directly pass information to the primary runspace.
			Using Set-PSFTaskEngineCache, they can store the information somewhere where the main runspace can retrieve it using this function.
		
		.PARAMETER Module
			The name of the module that generated the task.
			Use scriptname in case of using this within a script.
			Note: Must be the same as the name used within the task when calling 'Set-PSFTaskEngineCache'
		
		.PARAMETER Name
			The name of the task for which the cache is.
			Note: Must be the same as the name used within the task when calling 'Set-PSFTaskEngineCache'
		
		.EXAMPLE
			PS C:\> Get-PSFTaskEngineCache -Module 'mymodule' -Name 'maintenancetask'
	
			Retrieves the information stored under 'mymodule.maintenancetask'
	#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFTaskEngineCache')]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name
	)
	
	process
	{
		$cacheItem = [PSFramework.TaskEngine.TaskHost]::GetCacheItem($Module, $Name)
		if (-not $cacheItem) { return }
		
		$value = $cacheItem.GetValue()
		if ($null -ne $value) { $value }
	}
}
