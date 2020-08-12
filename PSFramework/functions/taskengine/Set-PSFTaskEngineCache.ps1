function Set-PSFTaskEngineCache
{
<#
	.SYNOPSIS
		Sets values and configuration for a cache entry.
	
	.DESCRIPTION
		Allows applying values and settings for a cache.
		This allows applying a lifetime to cached data or offering a mechanism to automatically refresh it on retrieval.
	
		This feature is specifically designed to interact with the Task Engine powershell task scheduler (See Register-PSFTaskEngineTask for details).
		However it is open for interaction with all tools.
		In particular, the cache is threadsafe to use through these functions.
		The cache is global to the process, NOT the current runspace.
		Background runspaces access the same data in a safe manner.
	
	.PARAMETER Module
		The name of the module that generated the task.
		Use scriptname in case of using this within a script.
	
	.PARAMETER Name
		The name of the task for which the cache is.
	
	.PARAMETER Value
		The value to set this cache to.
	
	.PARAMETER Lifetime
		How long values stored in this cache should remain valid.
	
	.PARAMETER Collector
		A scriptblock that is used to refresh the data cached.
		Should return values in a save manner, will be called if retrieving data on a cache that has expired.
	
	.PARAMETER CollectorArgument
		An argument to pass to the collector script.
		Allows passing in values as argument to the collector script.
		The arguments are stored persistently and are not subject to expiration.
	
	.EXAMPLE
		PS C:\> Set-PSFTaskEngineCache -Module 'mymodule' -Name 'maintenancetask' -Value $results
		
		Stores the content of $results in the cache 'mymodule / maintenancetask'
		These values can now be retrieved using Get-PSFTaskEngineCache.
	
	.EXAMPLE
		PS C:\> Set-PSFTaskEngineCache -Module MyModule -Name DomainController -Lifetime 8h -Collector { Get-ADDomainController }
	
		Registers a cache that lists all domain controllers in the current domain, keeping the data valid for 8 hours before refreshing it.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFTaskEngineCache')]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name,
		
		[AllowNull()]
		[object]
		$Value,
		
		[PsfValidateScript('PSFramework.Validate.TimeSpan.Positive', ErrorString = 'PSFramework.Validate.TimeSpan.Positive')]
		[PSFTimespan]
		$Lifetime,
		
		[System.Management.Automation.ScriptBlock]
		$Collector,
		
		[object]
		$CollectorArgument
	)
	
	process
	{
		if ([PSFramework.TaskEngine.TaskHost]::TestCacheItem($Module, $Name))
		{
			$cacheItem = [PSFramework.TaskEngine.TaskHost]::GetCacheItem($Module, $Name)
		}
		else { $cacheItem = [PSFramework.TaskEngine.TaskHost]::NewCacheItem($Module, $Name) }
		if (Test-PSFParameterBinding -ParameterName Value) { $cacheItem.Value = $Value }
		if (Test-PSFParameterBinding -ParameterName Lifetime) { $cacheItem.Expiration = $Lifetime }
		if (Test-PSFParameterBinding -ParameterName Collector) { $cacheItem.Collector = $Collector }
		if (Test-PSFParameterBinding -ParameterName CollectorArgument) { $cacheItem.CollectorArgument = $CollectorArgument }
	}
}