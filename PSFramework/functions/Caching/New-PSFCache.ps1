function New-PSFCache {
	<#
	.SYNOPSIS
		Create a new Cache object.
	
	.DESCRIPTION
		Create a new Cache object.
	
	.PARAMETER MaxItems
		The maximum number of items allowed in the cache.
	
	.PARAMETER Lifetime
		The maximum age for values in the cache.
	
	.PARAMETER TryDispose
		When expiring values from the cache, should we try to explicitly dispose them?
	
	.PARAMETER Collector
		When asking for a value that hasn't been cached yet, retrieve the value using this logic.
		Note: If this script fails, the retrieval errors.
	
	.PARAMETER CollectNull
		When executing the collector scriptblock, should we consider an empty / null return valid and cache it?
		This prevents repeated requests to the same key triggering the Collector script, which may save time.
		It also prevents it from noticing if something changed.
	
	.EXAMPLE
		PS C:\> New-PSFCache -MaxItems 50000

		Creates a cache that will retain the last 50000 items.

	.EXAMPLE
		PS C:\> New-PSFCache -Lifetime 30m

		Creates a cache that will retain values for 30 minutes.

	.EXAMPLE
		PS C:\> New-PSFCache -MaxItems 50000 -Collector { Get-ADGroup -Identity $_ }

		Creates a cache that will retain the last 50000 items, looking up Active Directory groups when asked for an entry it doesn't know yet.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[OutputType([PSFramework.Caching.CacheMemoryConcurrent])]
	[CmdletBinding()]
	param (
		[long]
		$MaxItems,

		[PsfTimeSpan]
		$Lifetime,

		[switch]
		$TryDispose,

		[PsfScriptBlock]
		$Collector,

		[switch]
		$CollectNull
	)
	process {
		$cache = [PSFramework.Caching.CacheMemoryConcurrent]::new()

		if ($MaxItems) { $cache.SetMaxItems($MaxItems) }
		if ($Lifetime) { $cache.SetLifetime($Lifetime) }
		if ($TryDispose) { $cache.SetTryDispose($TryDispose) }
		if ($Collector) { $cache.SetCollector($Collector) }
		if ($CollectNull) { $cache.SetCacheNull($CollectNull) }

		$cache
	}
}