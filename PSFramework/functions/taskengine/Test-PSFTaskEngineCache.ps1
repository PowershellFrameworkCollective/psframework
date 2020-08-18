function Test-PSFTaskEngineCache
{
	<#
		.SYNOPSIS
			Tests, whether the specified task engine cache-entry has been written.
		
		.DESCRIPTION
			Tests, whether the specified task engine cache-entry has been written.
		
		.PARAMETER Module
			The name of the module that generated the task.
			Use scriptname in case of using this within a script.
			Note: Must be the same as the name used within the task when calling 'Set-PSFTaskEngineCache'
		
		.PARAMETER Name
			The name of the task for which the cache is.
			Note: Must be the same as the name used within the task when calling 'Set-PSFTaskEngineCache'
		
		.EXAMPLE
			PS C:\> Test-PSFTaskEngineCache -Module 'mymodule' -Name 'maintenancetask'
	
			Returns, whether the cache has been set for the module 'mymodule' and the task 'maintenancetask'
			Does not require the cache to actually contain a value, but must exist.
	#>
	[OutputType([System.Boolean])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFTaskEngineCache')]
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
		[PSFramework.TaskEngine.TaskHost]::TestCacheItem($Module, $Name)
	}
}