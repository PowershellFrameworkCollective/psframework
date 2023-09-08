Describe "Get-PSFConfig Unit Tests" -Tag "CI", "Config", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module PSFTests -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	AfterAll {
		Get-PSFConfig -Module PSFTests -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Get-PSFConfig).ParameterSets.Name | Should -Be 'FullName', 'Module'
		(Get-Command Get-PSFConfig).Parameters.Keys | Should -Be 'FullName', 'Name', 'Module', 'Persisted', 'Force', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
	}
	
	It "Should find the correct Configuration item" {
		$config = New-Object PSFramework.Configuration.Config
		$config.Module = "psftests"
		$config.Name = "get-psfconfig.test1"
		[PSFramework.Configuration.ConfigurationHost]::Configurations[$config.FullName] = $config
		(Get-PSFConfig -FullName 'PSFTests.Get-PSFConfig.Test1').GetHashCode() | Should -Be ($config.GetHashCode())
	}
}