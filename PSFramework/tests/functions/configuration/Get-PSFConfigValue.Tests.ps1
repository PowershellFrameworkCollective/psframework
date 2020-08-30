Describe "Get-PSFConfigValue Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module Get-PSFConfigValue -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	AfterAll {
		Get-PSFConfig -Module Get-PSFConfigValue -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Get-PSFConfigValue).ParameterSets.Name | Should -Be '__AllParameterSets'
		foreach ($key in (Get-Command Get-PSFConfigValue).Parameters.Keys)
		{
			$key | Should -BeIn 'FullName', 'Fallback', 'NotNull', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
		}
	}
	
	# Return correct value
	# Return correct type
	# Fallback value working as designed
	# NotNull working as designed
	Describe "General functionality test" {
		BeforeAll {
			Set-PSFConfig -Module Get-PSFConfigValue -Name Setting1 -Value 42
			Set-PSFConfig -Module Get-PSFConfigValue -Name Setting2 -Value 23 -Validation integer
			Set-PSFConfig -Module Get-PSFConfigValue -Name Setting2 -Value "5"
		}
		
		It "Should return the correct value" {
			Get-PSFConfigValue -FullName 'Get-PSFConfigValue.Setting1' | Should -Be 42
			Get-PSFConfigValue -FullName 'Get-PSFConfigValue.Setting2' | Should -Be 5
		}
		
		It "Should return the correct type" {
			(Get-PSFConfigValue -FullName 'Get-PSFConfigValue.Setting1').GetType().FullName | Should -Be "System.Int32"
			(Get-PSFConfigValue -FullName 'Get-PSFConfigValue.Setting2').GetType().FullName | Should -Be "System.Int32"
		}
		
        It "Should offer the fallback value in absence of the actual value" {
			Get-PSFConfigValue -FullName 'Get-PSFConfigValue.Setting1' -Fallback 22 | Should -Be 42
			Get-PSFConfigValue -FullName 'Get-PSFConfigValue.Setting3' -Fallback 24 | Should -Be 24
		}
		
		It "Should correctly throw with NotNull set and no value provided" {
			{ Get-PSFConfigValue -FullName 'Get-PSFConfigValue.Setting1' -NotNull } | Should -Not -Throw
			{ Get-PSFConfigValue -FullName 'Get-PSFConfigValue.Setting3' -NotNull } | Should -Throw
		}
	}
}