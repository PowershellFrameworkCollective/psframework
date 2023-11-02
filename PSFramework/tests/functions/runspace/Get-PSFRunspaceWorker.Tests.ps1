Describe "Testing the command Get-PSFRunspaceWorker" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFRunspaceDispatcher | Remove-PSFRunspaceDispatcher

		$null = New-PSFRunspaceDispatcher -Name "Test1"
		Add-PSFRunspaceWorker -Name Node1 -InQueue Q1 -OutQueue Q2 -Count 1 -DispatcherName 'Test1' -ScriptBlock {}
		Add-PSFRunspaceWorker -Name Node2 -InQueue Q2 -OutQueue Q3 -Count 1 -DispatcherName 'Test1' -ScriptBlock {}
		Add-PSFRunspaceWorker -Name Node3 -InQueue Q3 -OutQueue Q4 -Count 1 -DispatcherName 'Test1' -ScriptBlock {}
		$null = New-PSFRunspaceDispatcher -Name "Test2"
		Add-PSFRunspaceWorker -Name NodeB1 -InQueue Q1 -OutQueue Q2 -Count 1 -DispatcherName 'Test2' -ScriptBlock {}
		Add-PSFRunspaceWorker -Name NodeB2 -InQueue Q2 -OutQueue Q3 -Count 1 -DispatcherName 'Test2' -ScriptBlock {}
	}
	AfterAll {
		Get-PSFRunspaceDispatcher | Remove-PSFRunspaceDispatcher
	}

	It "Should simply work (by name)" {
		Get-PSFRunspaceWorker -DispatcherName Test1 | Should -HaveCount 3
		Get-PSFRunspaceWorker -DispatcherName Test2 | Should -HaveCount 2
	}
	It "Should simply work (by object)" {
		Get-PSFRunspaceDispatcher -Name Test1 | Get-PSFRunspaceWorker | Should -HaveCount 3
		Get-PSFRunspaceDispatcher -Name Test2 | Get-PSFRunspaceWorker | Should -HaveCount 2
	}
	It "Should retrieve them all" {
		Get-PSFRunspaceDispatcher | Get-PSFRunspaceWorker | Should -HaveCount 5
	}
	It "Should filter correctly" {
		Get-PSFRunspaceDispatcher | Get-PSFRunspaceWorker -Name '*1' | Should -HaveCount 2
		Get-PSFRunspaceDispatcher | Get-PSFRunspaceWorker -Name 'NodeB*' | Should -HaveCount 2
	}
}