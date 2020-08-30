Describe "Remove-PSFConfig Unit Tests" -Tags "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module Remove-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	AfterAll {
		Get-PSFConfig -Module Remove-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Remove-PSFConfig).ParameterSets.Name | Should -Be 'Default', 'Name'
		foreach ($key in (Get-Command Remove-PSFConfig).Parameters.Keys)
		{
			$key | Should -BeIn 'Config', 'FullName', 'Module', 'Name', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'WhatIf', 'Confirm'
		}
	}
	
	# Create a deletable setting and delete it
	Describe "Basic configuration test for deletable configuration" {
		BeforeAll {
			Set-PSFConfig -Module Remove-PSFConfig -Name Test1 -Value 42 -AllowDelete
		}
		
		It "Should remove the configuration item from memory" {
			Get-PSFConfigValue -FullName Remove-PSFConfig.Test1 | Should -Be 42
			{ Get-PSFConfig -FullName 'Remove-PSFConfig.Test1' | Remove-PSFConfig -Confirm:$false } | Should -Not -Throw
			Get-PSFConfigValue -FullName Remove-PSFConfig.Test1 | Should -BeNullOrEmpty
		}
		
		It "Should fail when trying to remove a non-existing setting" {
			{ 'Remove-PSFConfig.Test1' | Remove-PSFConfig -Confirm:$false -ErrorAction Stop } | Should -Throw
		}
	}
	
	# Ensure configuration state policy
	Describe "Verifying deletion configuration states are respected" {
		It "should recognized a non-deletable configuration as such" {
			Set-PSFConfig -Module Remove-PSFConfig -Name Test2 -Value 42
			(Get-PSFConfig -Module Remove-PSFConfig -Name Test2).AllowDelete | Should -BeFalse
		}
		
		It "should allow changing deletability of non-initialized settings" {
			{ Set-PSFConfig -Module Remove-PSFConfig -Name Test2 -AllowDelete -EnableException } | Should -Not -Throw
			(Get-PSFConfig -Module Remove-PSFConfig -Name Test2).AllowDelete | Should -BeTrue
		}
		
		It "should overwrite the AllowDelete setting when initializing a setting" {
			{ Set-PSFConfig -Module Remove-PSFConfig -Name Test2 -Value 23 -Initialize -EnableException } | Should -Not -Throw
			(Get-PSFConfig -Module Remove-PSFConfig -Name Test2).AllowDelete | Should -BeFalse
			(Get-PSFConfig -Module Remove-PSFConfig -Name Test2).Value | Should -Be 42
		}
		
		It "should ignore AllowDelete setting when initializing a setting again" {
			{ Set-PSFConfig -Module Remove-PSFConfig -Name Test2 -Value 23 -Initialize -AllowDelete -EnableException } | Should -Not -Throw
			(Get-PSFConfig -Module Remove-PSFConfig -Name Test2).AllowDelete | Should -BeFalse
			(Get-PSFConfig -Module Remove-PSFConfig -Name Test2).Value | Should -Be 42
		}
		
		It "Should ignore AllowDeelte setting when applying to an initialized setting" {
			{ Set-PSFConfig -Module Remove-PSFConfig -Name Test2 -AllowDelete -EnableException } | Should -Not -Throw
			(Get-PSFConfig -Module Remove-PSFConfig -Name Test2).AllowDelete | Should -BeFalse
		}
	}
	
	# Ensure configuration deletion policy compliance
	Describe "Verifying deletion policy compliance is met" {
		BeforeAll {
			$configPlain = Set-PSFConfig -Module Remove-PSFConfig -Name Test3 -Value 1 -PassThru
			$configPolicy = Set-PSFConfig -Module Remove-PSFConfig -Name Test4 -Value 2 -AllowDelete -PassThru
			$configPolicy.PolicyEnforced = $true
		}
		
		
		It "Should refuse to delete a configuration setting not flagged for deletion" {
			{ $configPlain | Remove-PSFConfig -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
			Get-PSFConfig -Module Remove-PSFConfig -Name Test3 | Should -Not -BeNullOrEmpty
			(Get-PSFMessage | Select-Object -Last 1).String | Should -Be 'Configuration.Remove-PSFConfig.DeleteFailed'
			
			# Add another message to ensure the next test doesn't access the same message
			Write-PSFMessage -Message "Placeholder for test usage" -Level InternalComment
		}
		
		It "Should refuse to delete a configuration setting enforced by policy, even if flagged for deletion" {
			{ $configPolicy | Remove-PSFConfig -Confirm:$false -WarningAction SilentlyContinue } | Should -Not -Throw
			Get-PSFConfig -Module Remove-PSFConfig -Name Test4 | Should -Not -BeNullOrEmpty
			(Get-PSFMessage | Select-Object -Last 1).String | Should -Be 'Configuration.Remove-PSFConfig.DeleteFailed'
		}
	}
}