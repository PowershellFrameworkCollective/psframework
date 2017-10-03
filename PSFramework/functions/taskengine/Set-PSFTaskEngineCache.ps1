function Set-PSFTaskEngineCache
{
	<#
		.SYNOPSIS
			Sets the cache for a task engine task.
		
		.DESCRIPTION
			Sets the cache for a task engine task.
			Tasks executed by the task engine have no way to directly transfer output to the main runspace.
			This function is designed to work around this by providing a central storage.
			This function should only be called tasks scheduled to execute within the task engine.
		
		.PARAMETER Module
			The name of the module that generated the task.
			Use scriptname in case of using this within a script.
		
		.PARAMETER Name
			The name of the task for which the cache is.
		
		.PARAMETER Value
			The value to set this cache to.
		
		.EXAMPLE
			PS C:\> Set-PSFTaskEngineCache -Module 'mymodule' -Name 'maintenancetask' -Value $results
	
			Stores the content of $results in the cache 'mymodule / maintenancetask'
			These values can now be retrieved using Get-PSFTaskEngineCache.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[AllowNull()]
		$Value
	)
	
	$tempModule = $Module.ToLower()
	$tempName = $Name.ToLower()
	
	if (-not ([PSFramework.TaskEngine.TaskHost]::Cache.ContainsKey($tempModule)))
	{
		[PSFramework.TaskEngine.TaskHost]::Cache[$tempModule] = @{ }
	}
	
	[PSFramework.TaskEngine.TaskHost]::Cache[$tempModule][$tempName] = $Value
}