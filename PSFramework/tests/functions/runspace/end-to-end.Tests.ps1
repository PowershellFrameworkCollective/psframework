Describe "Testing the End-To-End Runspace Workflows" -Tag "CI", "Pipeline", "Inegration" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}
	AfterEach {
		Get-PSFRunspaceWorkflow | Remove-PSFRunspaceWorkflow
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}

	It "Should pass through input to output" {
		$workflow = New-PSFRunspaceWorkflow -Name "Test"
		$null = $workflow | Add-PSFRunspaceWorker -Name Node1 -InQueue Q1 -OutQueue Q2 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		}
		$null = $workflow | Add-PSFRunspaceWorker -Name Node2 -InQueue Q2 -OutQueue Q3 -Count 1 -ScriptBlock {
			$_
		}
		$null = $workflow | Add-PSFRunspaceWorker -Name Node3 -InQueue Q3 -OutQueue Q4 -Count 1 -ScriptBlock {
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

	It "Should pass through input to output with V2 Workers" {
		$workflow = New-PSFRunspaceWorkflow -Name "Test V2"
		$workflow | Add-PSFRunspaceWorker -Name Node1 -InQueue Q1 -OutQueue Q2 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		} -WorkerVersion 2
		$workflow | Add-PSFRunspaceWorker -Name Node2 -InQueue Q2 -OutQueue Q3 -Count 1 -ScriptBlock {
			$_
		} -WorkerVersion 2
		$workflow | Add-PSFRunspaceWorker -Name Node3 -InQueue Q3 -OutQueue Q4 -Count 1 -ScriptBlock {
			param ($Value)
			$Value
		} -WorkerVersion 2
		1..10 | ForEach-Object { Write-PSFRunspaceQueue -Name Q1 -Value $_ -InputObject $workflow }
		$workflow | Start-PSFRunspaceWorkflow
		Start-Sleep -Seconds 1

		$results = Read-PSFRunspaceQueue -InputObject $workflow -Name Q4 -All

		$results.Count | Should -Be 10
		($results | Measure-Object -Sum).Sum | Should -Be 55
	}

	It "Should Respect per-item timeouts" {
		Clear-PSFMessage
		$workflow = New-PSFRunspaceWorkflow -Name 'ExampleWorkflow'
		$worker = $workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 1 -ScriptBlock {
			Write-PSFMessage "Start"
			Start-Sleep -Milliseconds ($_ * 1000 + 500)
			Write-PSFMessage "Done"
			$_
		} -CloseOutQueue -Timeout '3s' -TimeoutType 'Start'
		$workflow | Write-PSFRunspaceQueue -Name Input -BulkValues (1..5) -Close
		$workflow | Start-PSFRunspaceWorkflow

		$workflow | Wait-PSFRunspaceWorkflow -Queue Done -Closed -PassThru -Timeout '1m' | Stop-PSFRunspaceWorkflow
		$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
		$workflow | Remove-PSFRunspaceWorkflow
		$messages = Get-PSFMessage

		$results | Should -Be 1, 2
		$worker.Errors | Should -HaveCount 3
		$messages | Should -HaveCount 7
		$messages | Where-Object Message -EQ Done | Should -HaveCount 2
		$messages | Where-Object Message -EQ Start | Should -HaveCount 5
		$($worker.Errors)[0].Error.ToString() | Should -Be 'Workitem timed out! ExampleWorkflow>Processing>0: 3'
		$($worker.Errors)[1].Error.ToString() | Should -Be 'Workitem timed out! ExampleWorkflow>Processing>0: 4'
		$($worker.Errors)[2].Error.ToString() | Should -Be 'Workitem timed out! ExampleWorkflow>Processing>0: 5'
	}
	
	It "Should Respect Idle Timeouts - Expired" {
		Clear-PSFMessage
		$workflow = New-PSFRunspaceWorkflow -Name 'ExampleWorkflow'
		$worker = $workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 1 -ScriptBlock {
			Write-PSFMessage "Start"
			Start-Sleep -Seconds 3
			Write-PSFMessage "Done"
			$_
		} -CloseOutQueue -Timeout '2s' -TimeoutType 'Idle'
		$workflow | Write-PSFRunspaceQueue -Name Input -Value 1 -Close
		$workflow | Start-PSFRunspaceWorkflow

		$workflow | Wait-PSFRunspaceWorkflow -Queue Done -Closed -PassThru -Timeout '1m' | Stop-PSFRunspaceWorkflow
		$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
		$workflow | Remove-PSFRunspaceWorkflow
		$messages = Get-PSFMessage

		$results | Should -BeNullOrEmpty
		$worker.Errors | Should -HaveCount 1
		$messages | Should -HaveCount 1
		$messages | Where-Object Message -EQ Done | Should -HaveCount 0
		$messages | Where-Object Message -EQ Start | Should -HaveCount 1
		$($worker.Errors)[0].Error.ToString() | Should -Be 'Workitem timed out! ExampleWorkflow>Processing>0: 1'
	}

	It "Should Respect Idle Timeouts - Worked" {
		Clear-PSFMessage
		$workflow = New-PSFRunspaceWorkflow -Name 'ExampleWorkflow'
		$worker = $workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 1 -ScriptBlock {
			Write-PSFMessage "Start"
			Start-Sleep -Seconds 1
			Write-PSFMessage "Processing"
			Start-Sleep -Seconds 1
			Write-PSFMessage "Processing"
			Start-Sleep -Seconds 1
			Write-PSFMessage "Done"
			$_
		} -CloseOutQueue -Timeout '2s' -TimeoutType 'Idle'
		$workflow | Write-PSFRunspaceQueue -Name Input -Value 1 -Close
		$workflow | Start-PSFRunspaceWorkflow

		$workflow | Wait-PSFRunspaceWorkflow -Queue Done -Closed -PassThru -Timeout '1m' | Stop-PSFRunspaceWorkflow
		$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
		$workflow | Remove-PSFRunspaceWorkflow
		$messages = Get-PSFMessage

		$results | Should -Be 1
		$worker.Errors | Should -HaveCount 0
		$messages | Should -HaveCount 4
		$messages | Where-Object Message -EQ Start | Should -HaveCount 1
		$messages | Where-Object Message -EQ Processing | Should -HaveCount 2
		$messages | Where-Object Message -EQ Done | Should -HaveCount 1
	}

	It "Should retry as configured" {
		Clear-PSFMessage
		$workflow = New-PSFRunspaceWorkflow -Name 'ExampleWorkflow'
		$worker = $workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 1 -ScriptBlock {
			Write-PSFMessage "Start"
			1 / 0
			Write-PSFMessage "Done"
			$_
		} -CloseOutQueue -RetryCount 3
		$workflow | Write-PSFRunspaceQueue -Name Input -Value 1 -Close
		$workflow | Start-PSFRunspaceWorkflow

		$workflow | Wait-PSFRunspaceWorkflow -Queue Done -Closed -PassThru -Timeout '1m' | Stop-PSFRunspaceWorkflow
		$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
		$workflow | Remove-PSFRunspaceWorkflow
		$messages = Get-PSFMessage

		$results | Should -BeNullOrEmpty
		$worker.Errors | Should -HaveCount 1
		$messages | Should -HaveCount 4
		$messages | Where-Object Message -EQ Start | Should -HaveCount 4
		$messages | Where-Object Message -EQ Done | Should -HaveCount 0
		$($worker.Errors)[0].Error.ToString() | Should -Be 'Attempted to divide by zero.'
	}

	Context "Should retry as configured and applicable" {
		BeforeAll {
			Clear-PSFMessage
			$workflow = New-PSFRunspaceWorkflow -Name 'ExampleWorkflow'
			$worker = $workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 1 -Scriptblock {
				Write-PSFMessage "Start: $_"
				1 / 0
				Write-PSFMessage "Done: $_"
				$_
			} -CloseOutQueue -RetryCount 3 -RetryCondition { $this -eq 1 }
			$workflow | Write-PSFRunspaceQueue -Name Input -BulkValues 1, 2 -Close
			$workflow | Start-PSFRunspaceWorkflow

			$workflow | Wait-PSFRunspaceWorkflow -Queue Done -Closed -PassThru -Timeout '1m' | Stop-PSFRunspaceWorkflow
			$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
			$workflow | Remove-PSFRunspaceWorkflow
			$messages = Get-PSFMessage
		}

		It "Should have no results" {
			$results | Should -BeNullOrEmpty
		}

		It "Should have failed twice and correctly" {
			$worker.Errors | Should -HaveCount 2
			$($worker.Errors)[0].Error.ToString() | Should -Be 'Attempted to divide by zero.'
			$($worker.Errors)[1].Error.ToString() | Should -Be 'Attempted to divide by zero.'
		}

		It "Should have generated 5 messages, none completed" {
			$messages | Should -HaveCount 5
			$messages | Where-Object Message -EQ 'Start: 1' | Should -HaveCount 4
			$messages | Where-Object Message -EQ 'Start: 2' | Should -HaveCount 1
			$messages | Where-Object Message -EQ Done | Should -HaveCount 0
		}
	}

	Context "Should execute Begin, Process, and End correctly V1" {
		BeforeAll {
			Clear-PSFMessage
			$workflow = New-PSFRunspaceWorkflow -Name 'ExampleWorkflow'
			$worker = $workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 1 -Begin {
				Write-PSFMessage "Beginning"
			} -Scriptblock {
				Write-PSFMessage "Processing: $_"
				$_
			} -End {
				Write-PSFMessage "Ending"
			} -CloseOutQueue
			$workflow | Write-PSFRunspaceQueue -Name Input -BulkValues (1..5) -Close
			$workflow | Start-PSFRunspaceWorkflow

			$workflow | Wait-PSFRunspaceWorkflow -Queue Done -Closed -PassThru -Timeout '1m' | Stop-PSFRunspaceWorkflow
			$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
			$workflow | Remove-PSFRunspaceWorkflow
			$messages = Get-PSFMessage
		}

		It "Should have 5 result numbers - 1, 2, 3, 4, 5" {
			$results | Should -Be 1, 2, 3, 4, 5
			$results | Should -HaveCount 5
		}

		It "Should have executed without errors" {
			$worker.Errors | Should -HaveCount 0
		}

		It "Should have the expected 7 Messages" {
			$messages | Should -HaveCount 7
			$messages | Where-Object Message -EQ 'Beginning' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 1' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 2' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 3' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 4' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 5' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Ending' | Should -HaveCount 1
		}

		It "Should have executed in the same Agent Runspace" {
			$messages | Group-Object Runspace | Should -HaveCount 1
			$messages | Where-Object Runspace -EQ ([runspace]::DefaultRunspace.InstanceId) | Should -HaveCount 0
		}
	}

	Context "Should execute Begin, Process, and End correctly V2" {
		BeforeAll {
			Clear-PSFMessage
			$workflow = New-PSFRunspaceWorkflow -Name 'ExampleWorkflow'
			$worker = $workflow | Add-PSFRunspaceWorker -Name Processing -InQueue Input -OutQueue Done -Count 1 -Begin {
				Write-PSFMessage "Beginning"
			} -Scriptblock {
				Write-PSFMessage "Processing: $_"
				$_
			} -End {
				Write-PSFMessage "Ending"
			} -CloseOutQueue -WorkerVersion 2
			$workflow | Write-PSFRunspaceQueue -Name Input -BulkValues (1..5) -Close
			$workflow | Start-PSFRunspaceWorkflow

			$workflow | Wait-PSFRunspaceWorkflow -Queue Done -Closed -PassThru -Timeout '1m' | Stop-PSFRunspaceWorkflow
			$results = $workflow | Read-PSFRunspaceQueue -Name Done -All
			$workflow | Remove-PSFRunspaceWorkflow
			$messages = Get-PSFMessage
		}

		It "Should have 5 result numbers - 1, 2, 3, 4, 5" {
			$results | Should -Be 1, 2, 3, 4, 5
			$results | Should -HaveCount 5
		}

		It "Should have executed without errors" {
			$worker.Errors | Should -HaveCount 0
		}

		It "Should have the expected 7 Messages" {
			$messages | Should -HaveCount 7
			$messages | Where-Object Message -EQ 'Beginning' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 1' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 2' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 3' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 4' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Processing: 5' | Should -HaveCount 1
			$messages | Where-Object Message -EQ 'Ending' | Should -HaveCount 1
		}

		It "Should have executed in the same Agent Runspace" {
			$messages | Group-Object Runspace | Should -HaveCount 1
			$messages | Where-Object Runspace -EQ ([runspace]::DefaultRunspace.InstanceId) | Should -HaveCount 0
		}
	}
}