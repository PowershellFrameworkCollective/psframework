Describe "New-PSFCache Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		$script:collectorCounter = 0
	}

	It "Should return a CacheMemoryConcurrent object" {
		$cache = New-PSFCache

		$cache.GetType().FullName | Should -Be 'PSFramework.Caching.CacheMemoryConcurrent'
		$cache.Count | Should -Be 0
	}

	It "Should configure max items and lifetime through constructor parameters" {
		$cache = New-PSFCache -MaxItems 3 -Lifetime 30s

		$cache.GetMaxItems() | Should -Be 3
		$cache.GetLifetime().TotalSeconds | Should -Be 30
	}

	It "Should configure TryDispose, Collector and CollectNull" {
		$collector = { "Collected:$($_)" }
		$cache = New-PSFCache -TryDispose -Collector $collector -CollectNull

		$cache.GetTryDispose() | Should -BeTrue
		$cache.GetCollector() | Should -Not -BeNullOrEmpty
		$cache.GetCollector().ToString() | Should -Match 'Collected:'
		$cache.GetCacheNull() | Should -BeTrue
	}

	It "Should support case-insensitive key access and Contains operations" {
		$cache = New-PSFCache
		$cache.Add('Alpha', 1)

		$cache.ContainsKey('alpha') | Should -BeTrue
		$cache.Contains('ALPHA') | Should -BeTrue
		$cache['aLpHa'] | Should -Be 1
	}

	It "Should update values through indexer set and retrieve latest value" {
		$cache = New-PSFCache
		$cache['Item'] = 1
		$cache['Item'] = 2

		$cache['Item'] | Should -Be 2
		$cache.Count | Should -Be 1
	}

	It "Should remove keys and ignore missing keys without error" {
		$cache = New-PSFCache
		$cache.Add('A', 1)
		$cache.Remove('A')

		$cache.ContainsKey('A') | Should -BeFalse
		{ $cache.Remove('DoesNotExist') } | Should -Not -Throw
	}

	It "Should enforce MaxItems by draining oldest entries" {
		$cache = New-PSFCache -MaxItems 2
		$cache.Add('A', 1)
		$cache.Add('B', 2)
		$cache.Add('C', 3)

		$cache.Count | Should -Be 2
		$cache.ContainsKey('A') | Should -BeFalse
		$cache.ContainsKey('B') | Should -BeTrue
		$cache.ContainsKey('C') | Should -BeTrue
	}

	It "Should expose non-expired entries through Count, Keys and Values" {
		$cache = New-PSFCache
		$cache.Add('One', 1)
		$cache.Add('Two', 2)

		$cache.Count | Should -Be 2
		$cache.Keys | Should -Contain 'One'
		$cache.Keys | Should -Contain 'Two'
		$cache.Values | Should -Contain 1
		$cache.Values | Should -Contain 2
	}

	It "Should enumerate as key-value pairs of current cache values" {
		$cache = New-PSFCache
		$cache.Add('One', 1)
		$cache.Add('Two', 2)

		$items = @($cache.GetEnumerator())
		$items.Count | Should -Be 2
		($items | Where-Object Key -eq 'One').Value | Should -Be 1
		($items | Where-Object Key -eq 'Two').Value | Should -Be 2
	}

	It "Should clone current values to a hashtable" {
		$cache = New-PSFCache
		$cache.Add('One', 1)
		$cache.Add('Two', 2)

		$clone = $cache.Clone()
		$clone | Should -BeOfType ([hashtable])
		$clone.Count | Should -Be 2
		$clone['one'] | Should -Be 1
		$clone['two'] | Should -Be 2
	}

	It "Should retrieve missing entries using Collector and cache them" {
		$cache = New-PSFCache -Collector {
			$script:collectorCounter++
			"Collected:$($_)"
		}

		$cache['Key1'] | Should -Be 'Collected:Key1'
		$cache['Key1'] | Should -Be 'Collected:Key1'
		$script:collectorCounter | Should -Be 1
		$cache.ContainsKey('Key1') | Should -BeTrue
	}

	It "Should not cache null collector results by default" {
		$cache = New-PSFCache -Collector {
			$script:collectorCounter++
			$null
		}

		$cache['NullKey'] | Should -BeNullOrEmpty
		$cache['NullKey'] | Should -BeNullOrEmpty
		$script:collectorCounter | Should -Be 2
		$cache.ContainsKey('NullKey') | Should -BeFalse
	}

	It "Should cache null collector results when CollectNull is set" {
		$cache = New-PSFCache -CollectNull -Collector {
			$script:collectorCounter++
			$null
		}

		$cache['NullKey'] | Should -BeNullOrEmpty
		$cache['NullKey'] | Should -BeNullOrEmpty
		$script:collectorCounter | Should -Be 1
		$cache.ContainsKey('NullKey') | Should -BeTrue
		$cache.Count | Should -Be 1
	}

	It "Should exclude expired entries from Count and key lookups" {
		$cache = New-PSFCache -Lifetime 1s
		$cache.Add('SoonExpired', 42)

		Start-Sleep -Milliseconds 1200

		$cache.ContainsKey('SoonExpired') | Should -BeFalse
		$cache.Count | Should -Be 0
		$cache.Keys | Should -Not -Contain 'SoonExpired'
	}

	It "Should dispose contained IDisposable values when TryDispose is enabled" {
		$cache = New-PSFCache -TryDispose
		$stream = [System.IO.MemoryStream]::new()
		$cache.Add('Stream', $stream)

		$cache.Remove('Stream')

		$stream.CanRead | Should -BeFalse
	}

	It "Should not dispose contained IDisposable values when TryDispose is disabled" {
		$cache = New-PSFCache
		$stream = [System.IO.MemoryStream]::new()
		$cache.Add('Stream', $stream)

		$cache.Remove('Stream')

		$stream.CanRead | Should -BeTrue
		$stream.Dispose()
	}
}
