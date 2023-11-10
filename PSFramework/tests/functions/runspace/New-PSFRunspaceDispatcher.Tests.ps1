Describe "Testing the command New-PSFRunspaceWorkflow" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}
	AfterAll {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}

	It "Should create a new Runspace Workflow without error" {
		{ New-PSFRunspaceWorkflow -Name "Test" } | Should -Not -Throw
	}
	It "Should return a workflow object with the correct name and no workers" {
		$workflow = New-PSFRunspaceWorkflow -Name "Test"
		$workflow | Should -Not -BeNullOrEmpty
		$workflow.Name | Should -Be 'Test'
		$workflow.Workers.Count | Should -Be 0
	}
	It "Should refuse creating a workflow that already exists" {
		$null = New-PSFRunspaceWorkflow -Name "Test"
		{ New-PSFRunspaceWorkflow -Name "Test" } | Should -Throw
	}
	It "Should overwrite a workflow that already exists when using Force" {
		$workflow = New-PSFRunspaceWorkflow -Name "Test"
		$workflow.Queues.Test.Enqueue(42)
		{ New-PSFRunspaceWorkflow -Name "Test" -Force } | Should -Not -Throw
		$newWorkflow = Get-PSFRunspaceWorkflow -Name Test
		$newWorkflow.Queues.Test.Count | Should -Be 0
	}
}