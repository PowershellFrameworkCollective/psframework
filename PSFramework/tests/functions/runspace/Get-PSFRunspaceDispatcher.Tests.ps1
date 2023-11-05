Describe "Testing the command Get-PSFRunspaceWorkflow" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
		$null = New-PSFRunspaceWorkflow -Name "Test1"
		$null = New-PSFRunspaceWorkflow -Name "Test2"
		$null = New-PSFRunspaceWorkflow -Name "Test3"
	}
	AfterAll {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}

	It "Should return all registered Runspace Workflows" {
		Get-PSFRunspaceWorkflow | Should -HaveCount 3
	}
	It "Should return the specified Runspace Workflows" {
		Get-PSFRunspaceWorkflow -Name Test1 | Should -HaveCount 1
		(Get-PSFRunspaceWorkflow -Name Test1).Name | Should -Be 'Test1'
	}
}