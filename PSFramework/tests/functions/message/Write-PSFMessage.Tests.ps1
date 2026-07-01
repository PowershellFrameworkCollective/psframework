Describe "Write-PSFMessage Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		function Invoke-ErrorStackTest {
			[CmdletBinding()]
			param ()

			try { 1 / 0 }
			catch { Write-PSFMessage -Message Failed -ErrorRecord $_ -ErrorStack }
		}
	}
	BeforeEach {
		Clear-PSFMessage
	}

	AfterAll {
		Clear-PSFMessage
	}

	It "Should expose the expected parameter sets" {
		$command = Get-Command Write-PSFMessage -ErrorAction Stop
		$command.ParameterSets.Name | Should -Contain 'Message'
		$command.ParameterSets.Name | Should -Contain 'String'
	}

	It "Should expose key parameters used by callers" {
		$command = Get-Command Write-PSFMessage -ErrorAction Stop
		$command.Parameters.Keys | Should -Contain 'Message'
		$command.Parameters.Keys | Should -Contain 'String'
		$command.Parameters.Keys | Should -Contain 'StringValues'
		$command.Parameters.Keys | Should -Contain 'Level'
		$command.Parameters.Keys | Should -Contain 'Tag'
		$command.Parameters.Keys | Should -Contain 'Data'
		$command.Parameters.Keys | Should -Contain 'Target'
		$command.Parameters.Keys | Should -Contain 'FunctionName'
		$command.Parameters.Keys | Should -Contain 'ModuleName'
		$command.Parameters.Keys | Should -Contain 'File'
		$command.Parameters.Keys | Should -Contain 'Line'
		$command.Parameters.Keys | Should -Contain 'Exception'
		$command.Parameters.Keys | Should -Contain 'ErrorRecord'
		$command.Parameters.Keys | Should -Contain 'OverrideExceptionMessage'
	}

	It "Should write a LogEntry object retrievable through Get-PSFMessage" {
		Write-PSFMessage -Message 'SimpleMessage' -Level Significant
		$entry = Get-PSFMessage | Select-Object -Last 1

		$entry | Should -Not -BeNullOrEmpty
		$entry.GetType().FullName | Should -Be 'PSFramework.Message.LogEntry'
		$entry.Message | Should -Be 'SimpleMessage'
		$entry.LogMessage | Should -Be 'SimpleMessage'
		$entry.Level.ToString() | Should -Be 'Significant'
		$entry.Runspace | Should -Be ([runspace]::DefaultRunspace.InstanceId)
		$entry.Username | Should -Not -BeNullOrEmpty
	}

	It "Should persist tags, data and target metadata" {
		$data = @{ Alpha = 1; Beta = 'two' }
		$target = [PSCustomObject]@{ Name = 'Target1'; Id = 42 }

		Write-PSFMessage -Message 'MetadataMessage' -Tag 'tagA', 'tagB' -Data $data -Target $target -Level Host
		$entry = Get-PSFMessage | Select-Object -Last 1

		$entry.Tags | Should -Contain 'tagA'
		$entry.Tags | Should -Contain 'tagB'
		$entry.Data.Alpha | Should -Be 1
		$entry.Data.Beta | Should -Be 'two'
		$entry.TargetObject | Should -Be $target
	}

	It "Should allow explicitly setting caller metadata fields" {
		Write-PSFMessage -Message 'MetaOverride' -FunctionName 'Invoke-TestFn' -ModuleName 'TestModule' -File 'C:\Temp\fake.ps1' -Line 321 -Level Important
		$entry = Get-PSFMessage | Select-Object -Last 1

		$entry.FunctionName | Should -Be 'Invoke-TestFn'
		$entry.ModuleName | Should -Be 'TestModule'
		$entry.File | Should -Be 'C:\Temp\fake.ps1'
		$entry.Line | Should -Be 321
	}

	It "Should format the Message using StringValues when provided" {
		Write-PSFMessage -Message 'Value: {0} / {1}' -StringValues 'A', 5 -Level Verbose
		$entry = Get-PSFMessage | Select-Object -Last 1

		$entry.Message | Should -Be 'Value: A / 5'
	}

	It "Should strip color tags in the logged message" {
		Write-PSFMessage -Message "<c='red'>Colored</c> output" -Level Important
		$entry = Get-PSFMessage | Select-Object -Last 1

		$entry.Message | Should -Be 'Colored output'
		$entry.LogMessage | Should -Be 'Colored output'
	}

	It "Should append exception text to message by default" {
		$exception = [System.InvalidOperationException]::new('Boom')
		Write-PSFMessage -Message 'Failure happened' -Exception $exception -Level Warning
		$entry = Get-PSFMessage | Select-Object -Last 1

		$entry.Message | Should -Be 'Failure happened | Boom'
		$entry.ErrorRecord | Should -Not -BeNullOrEmpty
	}

	It "Should respect OverrideExceptionMessage when exception is specified" {
		$exception = [System.InvalidOperationException]::new('Boom')
		Write-PSFMessage -Message 'Failure happened' -Exception $exception -OverrideExceptionMessage -Level Warning
		$entry = Get-PSFMessage | Select-Object -Last 1

		$entry.Message | Should -Be 'Failure happened'
		$entry.ErrorRecord | Should -Not -BeNullOrEmpty
	}

	It "Should avoid duplicate exception text when already present in message" {
		$exception = [System.InvalidOperationException]::new('Boom')
		$record = [System.Management.Automation.ErrorRecord]::new($exception, 'UnitTestError', [System.Management.Automation.ErrorCategory]::NotSpecified, $null)

		Write-PSFMessage -Message 'Failure happened | Boom' -ErrorRecord $record -Level Warning
		$entry = Get-PSFMessage | Select-Object -Last 1

		$entry.Message | Should -Be 'Failure happened | Boom'
		$entry.ErrorRecord | Should -Not -BeNullOrEmpty
	}

	It "Should use the error script stack when ErrorStack is specified" {
		{ Invoke-ErrorStackTest } | Should -Not -Throw
		
		$entry = Get-PSFMessage | Select-Object -Last 1
		$firstStackLine = ($entry.ErrorRecord.ScriptStackTrace -split "`r?`n" | Where-Object { $_ } | Select-Object -First 1)
		$expectedLine = [int]([regex]::Match($firstStackLine, '(\d+)$').Groups[1].Value)

		$entry.ErrorRecord | Should -Not -BeNullOrEmpty
		$entry.Message | Should -Be 'Failed | Attempted to divide by zero.'
		$entry.ErrorRecord.ScriptStackTrace | Should -Match 'Invoke-ErrorStackTest'
		$entry.ErrorRecord.ScriptStackTrace | Should -Match 'Write-PSFMessage.Tests.ps1: line \d+'
		$entry.CallStack.Entries | Should -Not -BeNullOrEmpty
		$entry.CallStack.Entries[0].FunctionName | Should -Be 'Invoke-ErrorStackTest'
		$entry.CallStack.Entries[0].File | Should -Match 'Write-PSFMessage.Tests.ps1'
		$entry.CallStack.Entries[0].Line | Should -BeGreaterThan 0
		$entry.CallStack.Entries[0].Line | Should -Be $expectedLine
	}
}
