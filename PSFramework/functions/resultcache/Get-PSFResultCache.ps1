function Get-PSFResultCache
{
<#
	.SYNOPSIS
		Returns the last stored result
	
	.DESCRIPTION
		Functions that implement the result cache store their information in the cache. This can then be retrieved by the user running this command.
		This forgives the user for forgetting to store the output in a variable and is especially precious when running commands that take a while to execute.
	
	.PARAMETER Type
		Default: Value
		Options: All, Value
		By default, this function will return the output that was cached during the last execution. However, this mode can be switched:
		- All: Returns everything that has been cached. This includes the name of the command calling Set-PFSResultCache as well as the timestamp when it was called.
		- Value: Returns just the object(s) that were written to cache
	
	.EXAMPLE
		PS C:\> Get-PSFResultCache
	
		Returns the latest cached result.
	
	.EXAMPLE
		PS C:\> Get-PSFResultCache -Type 'All'
	
		Returns a meta-information object containing the last result, when it was written and which function did the writing.
#>
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFResultCache')]
	param (
		[ValidateSet('Value','All')]
		[string]
		$Type = 'Value'
	)
	
	switch ($Type)
	{
		'All'
		{
			[pscustomobject]@{
				Result    = ([PSFramework.ResultCache.ResultCache]::Result)
				Function  = ([PSFramework.ResultCache.ResultCache]::Function)
				Timestamp = ([PSFramework.ResultCache.ResultCache]::Timestamp)
			}
		}
		'Value'
		{
			[PSFramework.ResultCache.ResultCache]::Result
		}
	}
}
if (-not (Test-Path "alias:Get-LastResult")) { New-Alias -Name Get-LastResult -Value Get-PSFResultCache -Description "A more intuitive name for users to call Get-PSFResultCache" }
if (-not (Test-Path "alias:glr")) { New-Alias -Name glr -Value Get-PSFResultCache -Description "A faster name for users to call Get-PSFResultCache" }