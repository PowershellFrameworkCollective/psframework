Describe "Testing the End-To-End Workflows" -Tag "CI", "Pipeline", "Inegration" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
	}
	AfterEach {
		Get-PSFRunspaceDispatcher | Remove-PSFRunspaceDispatcher
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
	}

	It "Should pass through input to output" {
		$dispatcher = New-PSFRunspaceDispatcher -Name "Test"
		$dispatcher | Add-PSFRunspaceWorker -Name Node1 -InQueue Q1 -OutQueue Q2 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		}
		$dispatcher | Add-PSFRunspaceWorker -Name Node2 -InQueue Q2 -OutQueue Q3 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		}
		$dispatcher | Add-PSFRunspaceWorker -Name Node3 -InQueue Q3 -OutQueue Q4 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		}
		1..10 | ForEach-Object { Write-PSFRunspaceQueue -Name Q1 -Value $_ -InputObject $dispatcher }
		$dispatcher | Start-PSFRunspaceDispatcher
		Start-Sleep -Seconds 1

		$results = Read-PSFRunspaceQueue -InputObject $dispatcher -Name Q4 -All

		$results.Count | Should -Be 10
		($results | Measure-Object -Sum).Sum | Should -Be 55
	}
}