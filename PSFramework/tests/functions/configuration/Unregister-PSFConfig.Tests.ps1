Describe "Unregister-PSFConfig Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module Unregister-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	AfterAll {
		Get-PSFConfig -Module Unregister-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Unregister-PSFConfig).ParameterSets.Name | Should -Be 'Pipeline', 'Module'
		$properties = 'ConfigurationItem', 'PersistedItem', 'FullName', 'Module', 'Name', 'Scope', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
		Compare-Object $properties ((Get-Command Unregister-PSFConfig).Parameters.Keys | Remove-PSFNull -Enumerate) | Should -BeNullOrEmpty
	}
	
	function New-Location
	{
		[CmdletBinding()]
		param (
			[PSFramework.Configuration.ConfigScope]
			$Scope,
			
			[string]
			$Path,
			
			[ValidateSet('Registry', 'File')]
			[string]
			$Type,
			
			[switch]
			$Elevated
		)
		
		if ($Type -eq 'File') { $configPath = Join-Path $Path 'psf_config.json' }
		else { $configPath = $Path }
		[pscustomobject]@{
			Scope    = $Scope
			Path	 = $Path
			Type	 = $Type
			Elevated = $Elevated.ToBool()
			ConfigPath = $configPath
		}
	}
	
	$module = Get-Module PSFramework | Sort-Object Version -Descending | Select-Object -First 1
	$pathRegistryUserDefault = & $module { $path_RegistryUserDefault }
	$pathRegistryUserEnforced = & $module { $path_RegistryUserEnforced }
	$pathRegistryMachineDefault = & $module { $path_RegistryMachineDefault }
	$pathRegistryMachineEnforced = & $module { $path_RegistryMachineEnforced }
	$pathFileUserLocal = & $module { $path_FileUserLocal }
	$pathFileUserShared = & $module { $path_FileUserShared }
	$pathFileSystem = & $module { $path_FileSystem }
	
	$locations = @()
	$locations += New-Location -Path $pathRegistryUserDefault -Type 'Registry' -Scope UserDefault
	$locations += New-Location -Path $pathRegistryUserEnforced -Type 'Registry' -Scope UserMandatory
	$locations += New-Location -Path $pathRegistryMachineDefault -Type 'Registry' -Elevated -Scope SystemDefault
	$locations += New-Location -Path $pathRegistryMachineEnforced -Type 'Registry' -Elevated -Scope SystemMandatory
	$locations += New-Location -Path $pathFileUserLocal -Type File -Scope FileUserLocal
	$locations += New-Location -Path $pathFileUserShared -Type File -Scope FileUserShared
	$locations += New-Location -Path $pathFileSystem -Type File -Elevated -Scope FileSystem
	
	$settingName1 = 'Unregister-PSFConfig.Phase1.Setting1'
	$settingName2 = 'Unregister-PSFConfig.Phase1.Setting2'
	$settingName3 = 'Unregister-PSFConfig.Phase1.Setting3'
	$config = @()
	$config += Set-PSFConfig -FullName $settingName1 -Value 23 -PassThru
	$config += Set-PSFConfig -FullName $settingName2 -Value 17 -PassThru
	$config += Set-PSFConfig -FullName $settingName3 -Value 42 -PassThru
	
	$variablesMain = @{
		module	     = $module
		locations    = $locations
		settingName1 = $settingName1
		settingName2 = $settingName2
		settingName3 = $settingName3
		config	     = $config
	}
	
	foreach ($location in $locations)
	{
		$variables = $variablesMain.Clone()
		$variables['location'] = $location
		
		# Don't test locations that require elevation to write to when not running elevated
		if ($location.Elevated -and (-not (Test-PSFPowerShell -Elevated)))
		{
			continue
		}
		
		Describe "Testing unregistration from scope $($location.Scope)" {
			switch ($location.Type)
			{
				'Registry'
				{
					It "Should properly set up configuration settings in registry" -TestCases $variables {
						if (Test-Path $location.Path)
						{
							(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
							(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
							(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
						}
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
					}
					It "Should properly remove a single setting by fullname" -TestCases $variables {
						Unregister-PSFConfig -FullName $settingName1 -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
					}
					It "Should properly remove multiple settings by fullname" -TestCases $variables {
						Unregister-PSFConfig -FullName $settingName2, $settingName3 -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
					It "Should properly remove all settings by fullname when piped to" -TestCases $variables {
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
						$settingName1, $settingName2, $settingName3 | Unregister-PSFConfig -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
					
					It "Should properly remove a single setting by config-item" -TestCases $variables {
						# Refresh Registry
						Register-PSFConfig -Config $config -Scope $location.Scope
						
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
						Unregister-PSFConfig -ConfigurationItem $config[0] -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
					}
					It "Should properly remove multiple settings by config-item" -TestCases $variables {
						Unregister-PSFConfig -ConfigurationItem $config[1..2] -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
					It "Should properly remove all settings by config-item when piped to" -TestCases $variables {
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
						$config | Unregister-PSFConfig -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
					
					It "Should properly remove a single setting by module and name" -TestCases $variables {
						# Refresh Registry
						Register-PSFConfig -Config $config -Scope $location.Scope
						
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
						Unregister-PSFConfig -Module 'Unregister-PSFConfig' -Name 'Phase1.Setting1' -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -Not -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -Not -BeNullOrEmpty
					}
					It "Should properly remove multiple settings by module and name" -TestCases $variables {
						Unregister-PSFConfig -Module 'Unregister-PSFConfig' -Scope $location.Scope
						(Get-ItemProperty -Path $location.Path).$settingName1 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName2 | Should -BeNullOrEmpty
						(Get-ItemProperty -Path $location.Path).$settingName3 | Should -BeNullOrEmpty
					}
				}
				'File'
				{
					It "Should properly set up configuration settings in the file system" -TestCases $variables {
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 3
					}
					It "Should properly remove a single setting by fullname" -TestCases $variables {
						Unregister-PSFConfig -FullName $settingName1 -Scope $location.Scope
						Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)" | Should -BeNullOrEmpty
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 2
					}
					It "Should properly remove multiple settings by fullname" -TestCases $variables {
						Unregister-PSFConfig -FullName $settingName2, $settingName3 -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
					It "Should properly remove all settings by fullname when piped to" -TestCases $variables {
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 3
						$settingName1, $settingName2, $settingName3 | Unregister-PSFConfig -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
					
					It "Should properly remove a single setting by config-item" -TestCases $variables {
						# Refresh Registry
						Register-PSFConfig -Config $config -Scope $location.Scope
						
						Unregister-PSFConfig -ConfigurationItem $config[0] -Scope $location.Scope
						Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)" | Should -BeNullOrEmpty
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 2
					}
					It "Should properly remove multiple settings by config-item" -TestCases $variables {
						Unregister-PSFConfig -ConfigurationItem $config[1..2] -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
					It "Should properly remove all settings by config-item when piped to" -TestCases $variables {
						Register-PSFConfig -Config $config -Scope $location.Scope
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 3
						$config | Unregister-PSFConfig -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
					
					It "Should properly remove a single setting by module and name" -TestCases $variables {
						# Refresh Registry
						Register-PSFConfig -Config $config -Scope $location.Scope
						
						Unregister-PSFConfig -Module 'Unregister-PSFConfig' -Name 'Phase1.Setting1' -Scope $location.Scope
						Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)" | Should -BeNullOrEmpty
						(Get-Content -Path $location.ConfigPath | Select-String "$($settingName2)|$($settingName3)" | Measure-Object).Count | Should -Be 2
					}
					It "Should properly remove multiple settings by module and name" -TestCases $variables {
						Unregister-PSFConfig -Module 'Unregister-PSFConfig' -Scope $location.Scope
						if (Test-Path $location.ConfigPath)
						{
							Get-Content -Path $location.ConfigPath | Select-String "$($settingName1)|$($settingName2)|$($settingName3)" | Should -BeNullOrEmpty
						}
					}
				}
			}
		}
	}
}