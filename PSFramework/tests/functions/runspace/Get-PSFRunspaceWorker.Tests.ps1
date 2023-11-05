Describe "Testing the command Get-PSFRunspaceWorker" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFRunspaceWorkflow | Remove-PSFRunspaceWorkflow

		$null = New-PSFRunspaceWorkflow -Name "Test1"
		Add-PSFRunspaceWorker -Name Node1 -InQueue Q1 -OutQueue Q2 -Count 1 -WorkflowName 'Test1' -ScriptBlock {}
		Add-PSFRunspaceWorker -Name Node2 -InQueue Q2 -OutQueue Q3 -Count 1 -WorkflowName 'Test1' -ScriptBlock {}
		Add-PSFRunspaceWorker -Name Node3 -InQueue Q3 -OutQueue Q4 -Count 1 -WorkflowName 'Test1' -ScriptBlock {}
		$null = New-PSFRunspaceWorkflow -Name "Test2"
		Add-PSFRunspaceWorker -Name NodeB1 -InQueue Q1 -OutQueue Q2 -Count 1 -WorkflowName 'Test2' -ScriptBlock {}
		Add-PSFRunspaceWorker -Name NodeB2 -InQueue Q2 -OutQueue Q3 -Count 1 -WorkflowName 'Test2' -ScriptBlock {}
	}
	AfterAll {
		Get-PSFRunspaceWorkflow | Remove-PSFRunspaceWorkflow
	}

	It "Should simply work (by name)" {
		Get-PSFRunspaceWorker -WorkflowName Test1 | Should -HaveCount 3
		Get-PSFRunspaceWorker -WorkflowName Test2 | Should -HaveCount 2
	}
	It "Should simply work (by object)" {
		Get-PSFRunspaceWorkflow -Name Test1 | Get-PSFRunspaceWorker | Should -HaveCount 3
		Get-PSFRunspaceWorkflow -Name Test2 | Get-PSFRunspaceWorker | Should -HaveCount 2
	}
	It "Should retrieve them all" {
		Get-PSFRunspaceWorkflow | Get-PSFRunspaceWorker | Should -HaveCount 5
	}
	It "Should filter correctly" {
		Get-PSFRunspaceWorkflow | Get-PSFRunspaceWorker -Name '*1' | Should -HaveCount 2
		Get-PSFRunspaceWorkflow | Get-PSFRunspaceWorker -Name 'NodeB*' | Should -HaveCount 2
	}
}