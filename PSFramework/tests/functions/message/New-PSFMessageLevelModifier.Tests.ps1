Describe "New-PSFMessageLevelModifier Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		[PSFramework.Message.MessageHost]::MessageLevelModifiers.Clear()
	}
	AfterAll {
		[PSFramework.Message.MessageHost]::MessageLevelModifiers.Clear()
	}
	It "Should create a new message level modifier without error and as defined" {
		{ New-PSFMessageLevelModifier -Name Test -Modifier -3 -IncludeFunctionName Get-Test -IncludeModuleName TestModule -IncludeTags Foo, Bar -EnableException } | Should -Not -Throw
		{ Write-PSFMessage -Message Test } | Should -Not -Throw

		$modifier = Get-PSFMessageLevelModifier
		$modifier.Name | Should -Be 'Test'
		$modifier.Modifier | Should -Be -3
		$modifier.IncludeFunctionName | Should -Be 'Get-Test'
		$modifier.IncludeModuleName | Should -Be TestModule
		$modifier.IncludeTags.Count | Should -Be 2
		$modifier.IncludeTags | Should -Contain Foo
		$modifier.IncludeTags | Should -Contain Bar
	}

	It "Should apply  filters correctly" {
		$modifier = Get-PSFMessageLevelModifier
		$modifier.AppliesTo("Get-Test","TestModule", @('Foo', 'Test')) | Should -BeTrue
		$modifier.AppliesTo("Get-Test","TestModule", @('Test')) | Should -BeFalse
		$modifier.AppliesTo("Get-Test","TestModule", @('Bar', 'Test')) | Should -BeTrue
		$modifier.AppliesTo("Get-Test2","TestModule", @('Foo', 'Test')) | Should -BeFalse
	}
}