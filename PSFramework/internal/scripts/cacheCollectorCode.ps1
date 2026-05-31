[PSFramework.Caching.CacheBase]::CollectorCode = {
	param ($Code)
	$cacheNull = $this.GetCacheNull()
	try { $result = $($Code.InvokeEx($false, $_, $_, $this, $false, $false, $_)) }
	catch { throw }

	if ($null -ne $result -or $cacheNull) {
		$this[$_] = $result
	}
}