Describe "ConvertTo-PSFHashtable Unit Tests" -Tag "UnitTests" {
	BeforeAll {
		$data = [PSCustomObject]@{
			Prop1 = 'value1'
			Prop2 = 'value2'
			Prop3 = 'value3'
			Prop4 = 'value4'
			Prop5 = 'value5'
		}

		$hash = @{
			Prop1 = 'value1'
			Prop2 = 'value2'
			Prop3 = 'value3'
			Prop4 = 'value4'
			Prop5 = 'value5'
		}

		$param = @{
			Path = "C:\Windows"
			Literalpath = 'C:\Windows'
			Force = $true
			Whatever = $true
		}
	}
	
	It "Should convert without an error" {
		{ $data | ConvertTo-PSFHashtable -ErrorAction Stop } | Should -Not -Throw
	}
	It "Should convert a custom object to hashtable" {
		$data | ConvertTo-PSFHashtable | Should -BeOfType ([hashtable])
	}
	It "Should convert a hashtable to hashtable" {
		$hash | ConvertTo-PSFHashtable | Should -BeOfType ([hashtable])
	}
	It "Should convert a .NET type to hashtable" {
		Get-Item . | ConvertTo-PSFHashtable | Should -BeOfType ([hashtable])
	}
	It "Should respect the -Include parameter" {
		$results = $data | ConvertTo-PSFHashtable -Include Prop1, Prop2
		$results.Count | Should -Be 2
		$results.Keys | Should -Contain Prop1
		$results.Keys | Should -Contain Prop2
	}
	It "Should respect the -Exclude parameter" {
		$results = $data | ConvertTo-PSFHashtable -Exclude Prop1, Prop2, Prop3
		$results.Count | Should -Be 2
		$results.Keys | Should -Contain Prop4
		$results.Keys | Should -Contain Prop5
	}
	It "Should -Remap correctly" {
		$results = $data | ConvertTo-PSFHashtable -Remap @{ Prop1 = 'Prop1A'; Prop2 = 'Prop2A' }
		$results.Count | Should -Be 5
		$results.Keys | Should -Contain Prop1A
		$results.Keys | Should -Contain Prop2A
		$results.Keys | Should -Contain Prop3
		$results.Keys | Should -Contain Prop4
		$results.Keys | Should -Contain Prop5
	}
	It "Should -Remap and -Exclude correctly" {
		$results = $data | ConvertTo-PSFHashtable -Remap @{ Prop1 = 'Prop1A'; Prop2 = 'Prop2A' } -Exclude Prop1, Prop3, Prop4
		$results.Count | Should -Be 2
		$results.Keys | Should -Contain Prop2A
		$results.Keys | Should -Contain Prop5
	}
	It "Should -Remap and -Include correctly" {
		$results = $data | ConvertTo-PSFHashtable -Remap @{ Prop1 = 'Prop1A'; Prop2 = 'Prop2A' } -Include Prop1, Prop3
		$results.Count | Should -Be 3
		$results.Keys | Should -Contain Prop1A
		$results.Keys | Should -Contain Prop2A
		$results.Keys | Should -Contain Prop3
	}
	It "Should return Case Sensitive when required" {
		$results = $hash | ConvertTo-PSFHashtable -CaseSensitive
		$results.Count | Should -Be 5
		$results['prop1'] = 42
		$results.Count | Should -Be 6
		$results['prop1'] | Should -Be 42
		$results['Prop1'] | Should -Be 'value1'
	}
	It "Should be -CaseSensitive together with -Include" {
		$results = $hash | ConvertTo-PSFHashtable -CaseSensitive -Include Prop1, prop2
		$results.Count | Should -Be 1
		$results.Keys | Should -Contain 'Prop1'
		$results.Keys | Should -Not -Contain 'Prop2'
	}
	It "Should be -CaseSensitive together with -Exclude" {
		$results = $hash | ConvertTo-PSFHashtable -CaseSensitive -Exclude Prop2, Prop3, Prop4, prop5
		$results.Count | Should -Be 2
		$results.Keys | Should -Contain 'Prop1'
		$results.Keys | Should -Contain 'Prop5'
	}
	It "Should -Inherit existing variables" {
		$prop6 = 42
		$results = $data | ConvertTo-PSFHashtable -Include Prop1, Prop6 -Inherit
		$results.Count | Should -Be 2
		$results.Keys | Should -Contain 'Prop1'
		$results.Keys | Should -Contain 'Prop6'
		$results.Prop6 | Should -Be 42
	}
	It "Should get input from a reference command" {
		$results = $param | ConvertTo-PSFHashtable -ReferenceCommand Get-ChildItem
		$results.Count | Should -Be 3
		$results.Keys | Should -Contain 'Path'
		$results.Keys | Should -Contain 'Literalpath'
		$results.Keys | Should -Contain 'Force'
	}
	It "Should correctly select by Reference Parameter Set Name" {
		$results = $param | ConvertTo-PSFHashtable -ReferenceCommand Get-ChildItem -ReferenceParameterSetName Items
		$results.Count | Should -Be 2
		$results.Keys | Should -Contain 'Path'
		$results.Keys | Should -Contain 'Force'
	}
	It "Should correctly select by Reference Parameter Set Name with -ReMap" {
		$results = $param | ConvertTo-PSFHashtable -ReferenceCommand Get-ChildItem -ReferenceParameterSetName Items -Remap @{ Whatever = 'Recurse' }
		$results.Count | Should -Be 3
		$results.Keys | Should -Contain 'Path'
		$results.Keys | Should -Contain 'Force'
		$results.Keys | Should -Contain 'Recurse'
	}
}