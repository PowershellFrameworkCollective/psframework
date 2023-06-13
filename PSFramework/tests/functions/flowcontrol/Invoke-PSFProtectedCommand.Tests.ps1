Describe "Invoke-PSFProtectedCommand unit tests" -Tag "UnitTests" {
	BeforeAll {
		#region Functions
		function Get-Test {
			[CmdletBinding(SupportsShouldProcess = $true)]
			param (
				[string]
				$Action = "Testing",
		
				[object]
				$Target = 42,
		
				[switch]
				$Fail,
		
				[int]
				$RetryCount,
		
				[int]
				$RetryWait,
		
				[scriptblock]
				$ErrorEvent,
		
				[switch]
				$EnableException,

				[int]
				$SucceedAfter
			)
		
			$global:__psf_failed = $false
		
			$param = @{
				Action          = $Action
				Target          = $Target
				EnableException = $EnableException
			}
			if ($RetryCount) { $param.RetryCount = $RetryCount }
			if ($RetryWait) { $param.RetryWait = $RetryWait }
			if ($ErrorEvent) { $param.ErrorEvent = $ErrorEvent }
			
			$testVar = 1
			Write-PSFMessage -Message "Test Var: {0}" -StringValues $testVar
			$count = 0
			Invoke-PSFProtectedCommand @param -ScriptBlock {
				$testVar = 2
				if ($Fail) { throw "Failing!"}
				if ($count -ge $SucceedAfter) { "Success" }
				else {
					$count++
					throw "Still failing ($count / $SucceedAfter)"
				}
			} -PSCmdlet $PSCmdlet
			Write-PSFMessage -Message "Test Var after: {0}" -StringValues $testVar
		
			if (Test-PSFFunctionInterrupt) {
				$global:__psf_failed = $true
			}
		}
		#endregion Functions

		Clear-PSFMessage
	}
	AfterAll {
		Clear-PSFMessage
	}

	# Simple Attempt
	It "Should just work most of the time" {
		Clear-PSFMessage
		{ Get-Test } | Should -Not -Throw
		(Get-PSFMessage).Count | Should -Be 4
		(Get-PSFMessage).Message | Should -Contain "Test Var: 1"
		(Get-PSFMessage).Message | Should -Contain "Execution Confirmed: Testing"
		(Get-PSFMessage).Message | Should -Contain "Execution Successful: Testing"
		(Get-PSFMessage).Message | Should -Contain "Test Var after: 2"
		$global:__psf_failed | Should -BeFalse
	}

	# Simple Attempt (Failed)
	It "Should fail correctly (With Enable Exception)" {
		Clear-PSFMessage
		{ Get-Test -Fail -EnableException } | Should -Throw
		(Get-PSFMessage).Count | Should -Be 3
		(Get-PSFMessage).Message | Should -Contain "Test Var: 1"
		(Get-PSFMessage).Message | Should -Contain "Execution Confirmed: Testing"
		(Get-PSFMessage).Message | Should -Contain "Failed to: Testing | Failing!"
		$global:__psf_failed | Should -BeFalse
	}

	# Retry Attempt (No Failure)
	It "Should work with the retry options without issues when all is well" {
		Clear-PSFMessage
		{ Get-Test -RetryCount 3 -RetryWait 1 } | Should -Not -Throw
		(Get-PSFMessage).Count | Should -Be 4
		(Get-PSFMessage).Message | Should -Contain "Test Var: 1"
		(Get-PSFMessage).Message | Should -Contain "Execution Confirmed: Testing"
		(Get-PSFMessage).Message | Should -Contain "Execution Successful: Testing"
		(Get-PSFMessage).Message | Should -Contain "Test Var after: 2"
		$global:__psf_failed | Should -BeFalse
	}

	# Retry Attempt (Success on 3rd)
	It "Should work with the retry options when it only works after a few failures" {
		Clear-PSFMessage
		{ Get-Test -RetryCount 3 -RetryWait 1 -SucceedAfter 2 } | Should -Not -Throw
		(Get-PSFMessage).Count | Should -Be 6
		(Get-PSFMessage).Message | Should -Contain "Test Var: 1"
		(Get-PSFMessage).Message | Should -Contain "Execution Confirmed: Testing"
		(Get-PSFMessage).Message | Should -Contain "Failed 1 / 4 attempts, trying again: Testing"
		(Get-PSFMessage).Message | Should -Contain "Failed 2 / 4 attempts, trying again: Testing"
		(Get-PSFMessage).Message | Should -Contain "Execution Successful: Testing"
		(Get-PSFMessage).Message | Should -Contain "Test Var after: 2"
		$global:__psf_failed | Should -BeFalse
	}

	# Retry Attempt (Failed)
	It "Even with the retry options it should fail correctly, if success never happens" {
		Clear-PSFMessage
		{ Get-Test -RetryCount 3 -RetryWait 1 -Fail -EnableException } | Should -Throw
		(Get-PSFMessage).Count | Should -Be 6
		(Get-PSFMessage).Message | Should -Contain "Test Var: 1"
		(Get-PSFMessage).Message | Should -Contain "Execution Confirmed: Testing"
		(Get-PSFMessage).Message | Should -Contain "Failed 1 / 4 attempts, trying again: Testing"
		(Get-PSFMessage).Message | Should -Contain "Failed 2 / 4 attempts, trying again: Testing"
		(Get-PSFMessage).Message | Should -Contain "Failed 3 / 4 attempts, trying again: Testing"
		(Get-PSFMessage).Message | Should -Contain "Failed to: Testing | Failing!"
		$global:__psf_failed | Should -BeFalse
	}

	# Error Event
	It "Should error out as requested and still be able to execute the error event" {
		Clear-PSFMessage
		$event = { Write-PSFMessage "ErrorEvent Message" }
		{ Get-Test -Fail -EnableException -ErrorEvent $event } | Should -Throw
		(Get-PSFMessage).Count | Should -Be 6
		(Get-PSFMessage).Message | Should -Contain 'Test Var: 1'
		(Get-PSFMessage).Message | Should -Contain 'Execution Confirmed: Testing'
		(Get-PSFMessage).Message | Should -Contain 'Executing error event for "Testing" against 42'
		(Get-PSFMessage).Message | Should -Contain 'ErrorEvent Message'
		(Get-PSFMessage).Message | Should -Contain 'Successfully executed error event for "Testing" against 42'
		(Get-PSFMessage).Message | Should -Contain 'Failed to: Testing | Failing!'
		$global:__psf_failed | Should -BeFalse
	}

	# No Error failure
	It "Should handle failure without exception as expected, triggering the command termination flag" {
		Clear-PSFMessage
		{ Get-Test -Fail } | Should -Not -Throw
		(Get-PSFMessage).Count | Should -Be 4
		(Get-PSFMessage).Message | Should -Contain 'Test Var: 1'
		(Get-PSFMessage).Message | Should -Contain 'Execution Confirmed: Testing'
		(Get-PSFMessage).Message | Should -Contain 'Failed to: Testing | Failing!'
		(Get-PSFMessage).Message | Should -Contain 'Test Var after: 2'
		$global:__psf_failed | Should -BeTrue
	}

	# Error Event & No Error failure
	It "Should be able to handle both non-exception failure AND error events" {
		Clear-PSFMessage
		$event = { Write-PSFMessage "ErrorEvent Message" }
		{ Get-Test -Fail -ErrorEvent $event } | Should -Not -Throw
		(Get-PSFMessage).Count | Should -Be 7
		(Get-PSFMessage).Message | Should -Contain 'Test Var: 1'
		(Get-PSFMessage).Message | Should -Contain 'Execution Confirmed: Testing'
		(Get-PSFMessage).Message | Should -Contain 'Executing error event for "Testing" against 42'
		(Get-PSFMessage).Message | Should -Contain 'ErrorEvent Message'
		(Get-PSFMessage).Message | Should -Contain 'Successfully executed error event for "Testing" against 42'
		(Get-PSFMessage).Message | Should -Contain 'Failed to: Testing | Failing!'
		(Get-PSFMessage).Message | Should -Contain 'Test Var after: 2'
		$global:__psf_failed | Should -BeTrue
	}
}