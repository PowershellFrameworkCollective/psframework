Describe "Testing the End-To-End Workflows" -Tag "CI", "Pipeline", "Inegration" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}
	AfterEach {
		Get-PSFRunspaceWorkflow | Remove-PSFRunspaceWorkflow
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}

	It "Should pass through input to output" {
		$workflow = New-PSFRunspaceWorkflow -Name "Test"
		$workflow | Add-PSFRunspaceWorker -Name Node1 -InQueue Q1 -OutQueue Q2 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		}
		$workflow | Add-PSFRunspaceWorker -Name Node2 -InQueue Q2 -OutQueue Q3 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		}
		$workflow | Add-PSFRunspaceWorker -Name Node3 -InQueue Q3 -OutQueue Q4 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		}
		1..10 | ForEach-Object { Write-PSFRunspaceQueue -Name Q1 -Value $_ -InputObject $workflow }
		$workflow | Start-PSFRunspaceWorkflow
		Start-Sleep -Seconds 1

		$results = Read-PSFRunspaceQueue -InputObject $workflow -Name Q4 -All

		$results.Count | Should -Be 10
		($results | Measure-Object -Sum).Sum | Should -Be 55
	}
}