function Set-PSFResultCache
{
<#
	.SYNOPSIS
		Stores a result in the result cache
	
	.DESCRIPTION
		Stores a result in the result cache.
		This function is designed for use in other functions, a user should never have cause to use it directly himself.
	
	.PARAMETER InputObject
		The value to store in the result cache.
	
	.PARAMETER DisableCache
		Allows you to control, whether the function actually writes to the cache. Useful when used in combination with -PassThru.
		Does not suppress output via -PassThru. However in combination, these two parameters make caching within a pipeline practical.
	
	.PARAMETER PassThru
		The objects that are being cached are passed through this function.
		By default, Set-PSFResultCache doesn't have any output.
	
	.PARAMETER CommandName
		Default: (Get-PSCallStack)[0].Command
		The name of the command that called Set-PSFResultCache.
		Is automatically detected and usually doesn't need to be changed.
	
	.EXAMPLE
		PS C:\> Set-PSFResultCache -InputObject $Results -DisableCache $NoRes
		
		Stores the contents of $Results in the result cache, but does nothing if $NoRes is $true (the default Switch-name for disabling the result cache)
	
	.EXAMPLE
		PS C:\> Get-ChildItem $path | Get-Acl | Set-PSFResultCache -DisableCache $NoRes -PassThru
		
		Gets all items in $Path, then retrieves each of their Acl, finally it stores those in the result cache (if it isn't disabled via $NoRes) and finally passes each Acl through for the user to see.
		This will return all objects, even if $NoRes is set to $True.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFResultCache')]
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[AllowEmptyCollection()]
		[AllowEmptyString()]
		[AllowNull()]
		[Alias('Value')]
		[Object]
		$InputObject,
		
		[boolean]
		$DisableCache = $false,
		
		[Switch]
		$PassThru,
		
		[string]
		$CommandName = (Get-PSCallStack)[0].Command
	)
	
	begin
	{
		$isPipeline = -not $PSBoundParameters.ContainsKey("InputObject")
		[PSFramework.ResultCache.ResultCache]::Function = $CommandName
		
		if ($isPipeline -and -not $DisableCache)
		{
			[PSFramework.ResultCache.ResultCache]::Result = [System.Collections.ArrayList]@()
		}
	}
	process
	{
		if (-not $DisableCache)
		{
			if ($isPipeline) { $null = [PSFramework.ResultCache.ResultCache]::Result.Add($InputObject) }
			else { [PSFramework.ResultCache.ResultCache]::Result = $InputObject }
		}
		if ($PassThru) { $InputObject }
	}
	end
	{
		if ($isPipeline -and -not $DisableCache)
		{
			[PSFramework.ResultCache.ResultCache]::Result = [PSFramework.ResultCache.ResultCache]::Result.ToArray()
		}
	}
}