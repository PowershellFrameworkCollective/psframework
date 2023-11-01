Describe "Testing the command New-PSFRunspaceDispatcher" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
	}
	AfterAll {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
	}

	It "Should create a new Runspace Dispatcher without error" {
		{ New-PSFRunspaceDispatcher -Name "Test" } | Should -Not -Throw
	}
	It "Should return a dispatcher object with the correct name and no workers" {
		$dispatcher = New-PSFRunspaceDispatcher -Name "Test"
		$dispatcher | Should -Not -BeNullOrEmpty
		$dispatcher.Name | Should -Be 'Test'
		$dispatcher.Workers.Count | Should -Be 0
	}
	It "Should refuse creating a dispatcher that already exists" {
		$null = New-PSFRunspaceDispatcher -Name "Test"
		{ New-PSFRunspaceDispatcher -Name "Test" } | Should -Throw
	}
	It "Should overwrite a dispatcher that already exists when using Force" {
		$dispatcher = New-PSFRunspaceDispatcher -Name "Test"
		$dispatcher.Queues.Test.Enqueue(42)
		{ New-PSFRunspaceDispatcher -Name "Test" -Force } | Should -Not -Throw
		$newDispatcher = Get-PSFRunspaceDispatcher -Name Test
		$newDispatcher.Queues.Test.Count | Should -Be 0
	}
}