Describe "Testing the command Get-PSFRunspaceDispatcher" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
		$null = New-PSFRunspaceDispatcher -Name "Test1"
		$null = New-PSFRunspaceDispatcher -Name "Test2"
		$null = New-PSFRunspaceDispatcher -Name "Test3"
	}
	AfterAll {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
	}

	It "Should return all registered Runspace Dispatchers" {
		Get-PSFRunspaceDispatcher | Should -HaveCount 3
	}
	It "Should return the specified Runspace Dispatchers" {
		Get-PSFRunspaceDispatcher -Name Test1 | Should -HaveCount 1
		(Get-PSFRunspaceDispatcher -Name Test1).Name | Should -Be 'Test1'
	}
}