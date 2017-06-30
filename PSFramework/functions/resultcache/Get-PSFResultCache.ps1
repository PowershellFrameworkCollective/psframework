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
		PS C:\> Get-PSFResultCache -Type
	
		Returns a meta-information object containing the last result, when it was written and which function did the writing.
#>
	
	[CmdletBinding()]
	param (
		[ValidateSet('Value','All')]
		[string]
		$Type = 'Value'
	)
	
	switch ($Type)
	{
		'All'
		{
			New-Object PSObject -Property @{
				Result    = ([PSFramework.Utility.ResultCache]::Result)
				Function  = ([PSFramework.Utility.ResultCache]::Function)
				Timestamp = ([PSFramework.Utility.ResultCache]::Timestamp)
			}
		}
		'Value'
		{
			[PSFramework.Utility.ResultCache]::Result
		}
	}
}
New-Alias -Name Get-LastResult -Value Get-PSFResultCache -Option AllScope -Description "A more intuitive name for users to call Get-PSFResultCache"
New-Alias -Name glr -Value Get-PSFResultCache -Option AllScope -Description "A faster name for users to call Get-PSFResultCache"