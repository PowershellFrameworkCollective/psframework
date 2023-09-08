Describe "Export-PSFConfig Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module Export-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		Remove-Item -Path "TestDrive:\Export-PSFConfig*" -Force -Recurse
	}
	AfterAll {
		Get-PSFConfig -Module Export-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		Remove-Item -Path "TestDrive:\Export-PSFConfig*" -Force -Recurse
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Export-PSFConfig).ParameterSets.Name | Should -Be 'FullName', 'Module', 'Config', 'ModuleName'
		foreach ($key in (Get-Command Export-PSFConfig).Parameters.Keys)
		{
			$key | Should -BeIn 'FullName', 'Module', 'Name', 'Config', 'ModuleName', 'ModuleVersion', 'Scope', 'OutPath', 'SkipUnchanged', 'EnableException', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
		}
	}
	
	# Export 1 Configuration Item to file
	# Export 3 Configuration Items to file
	# Export all configuration items of a module to file
	# Export all (and only) unchanged items of a module to file
	Describe "Testing core export integrity" {
		BeforeAll {
			$configItems = @()
			$configItems += Set-PSFConfig -FullName Export-PSFConfig.TestPhase1.Settings1 -Value 42 -PassThru -Initialize
			$configItems += Set-PSFConfig -FullName Export-PSFConfig.TestPhase1.Settings2 -Value 23 -PassThru -Initialize
			$configItems += Set-PSFConfig -FullName Export-PSFConfig.TestPhase1.Settings3 -Value "foo" -PassThru -Initialize
		}
		
		It "Should correctly export a single configuration item" {
			$configItems[0] | Export-PSFConfig -OutPath "TestDrive:\Export-PSFConfig.test1.json"
			Test-Path "TestDrive:\Export-PSFConfig.test1.json" | Should -Be $true
			$item = Get-Content "TestDrive:\Export-PSFConfig.test1.json" | ConvertFrom-Json
			$item.FullName | Should -Be 'Export-PSFConfig.TestPhase1.Settings1'
			$item.Type | Should -Be 3
			$item.Version | Should -Be 1
			$item.Value | Should -Be "42"
			$item.Style | Should -Be "Default"
		}
		It "Should correctly export multiple configuration items" {
			$configItems | Export-PSFConfig -OutPath "TestDrive:\Export-PSFConfig.test2.json"
			Test-Path "TestDrive:\Export-PSFConfig.test2.json" | Should -Be $true
			$items = Get-Content "TestDrive:\Export-PSFConfig.test2.json" | ConvertFrom-Json
			foreach ($name in ('Export-PSFConfig.TestPhase1.Settings1', 'Export-PSFConfig.TestPhase1.Settings2', 'Export-PSFConfig.TestPhase1.Settings3'))
			{
				$name | Should -BeIn $items.FullName
			}
			(($items.Type | Group-Object | Sort-Object Count) | Where-Object Name -EQ 3).Count | Should -Be 2
			(($items.Type | Group-Object | Sort-Object Count) | Where-Object Name -EQ 6).Count | Should -Be 1
			$items.Version | Should -Be 1, 1, 1
			$items.Value | Should -Contain "foo"
			$items.Value | Should -Contain "42"
			$items.Value | Should -Contain "23"
			$items.Count | Should -Be 3
			$items.Style | Should -Be "Default", "Default", "Default"
		}
		It "Should export all settings belonging to the specified module" {
			Export-PSFConfig -Module Export-PSFConfig -OutPath "TestDrive:\Export-PSFConfig.test3.json"
			Test-Path "TestDrive:\Export-PSFConfig.test3.json" | Should -Be $true
			(Get-Content "TestDrive:\Export-PSFConfig.test3.json" | ConvertFrom-Json | Remove-PSFNull -Enumerate | Measure-Object).Count | Should -Be 3
		}
		It "Should only export changed settings if so directed" {
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase1.Settings2 -Value 23
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase1.Settings3 -Value "bar"
			Export-PSFConfig -Module Export-PSFConfig -OutPath "TestDrive:\Export-PSFConfig.test4.json" -SkipUnchanged
			Test-Path "TestDrive:\Export-PSFConfig.test4.json" | Should -Be $true
			(Get-Content "TestDrive:\Export-PSFConfig.test4.json" | ConvertFrom-Json | Remove-PSFNull -Enumerate | Measure-Object).Count | Should -Be 2
		}
	}
	
	# Determine file integrity
	# - Simple Export
	# - Complex Export
	# - Simple/Complex in hybrid export
	Describe "Ensuring all export styles are correctly created" {
		BeforeAll {
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase2.Settings1 -Value 42 -SimpleExport
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase2.Settings2 -Value 23
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase2.Settings3 -Value (Get-Date) -SimpleExport
		}
		
		It "Should create a simple export" {
			Export-PSFConfig -FullName Export-PSFConfig.TestPhase2.Settings1 -OutPath "TestDrive:\Export-PSFConfig.testB1.json"
			Test-Path "TestDrive:\Export-PSFConfig.testB1.json" | Should -Be $true
			$item = Get-Content "TestDrive:\Export-PSFConfig.testB1.json" | ConvertFrom-Json
			$item.FullName | Should -Be 'Export-PSFConfig.TestPhase2.Settings1'
			$item.Version | Should -Be 1
			$item.Data | Should -Be 42
			$item.Data.GetType().FullName | Should -BeIn "System.Int32","System.Int64" # ConvertFrom-Json on later PS versions converts all numbers to long
			
			# Properties that only exist on non-simple export items
			$item.Style | Should -BeNullOrEmpty
			$item.Type | Should -BeNullOrEmpty
			$item.Value | Should -BeNullOrEmpty
		}
		It "Should create a complex export" {
			Export-PSFConfig -FullName Export-PSFConfig.TestPhase2.Settings2 -OutPath "TestDrive:\Export-PSFConfig.testB2.json"
			Test-Path "TestDrive:\Export-PSFConfig.testB2.json" | Should -Be $true
			$item = Get-Content "TestDrive:\Export-PSFConfig.testB2.json" | ConvertFrom-Json
			$item.FullName | Should -Be 'Export-PSFConfig.TestPhase2.Settings2'
			$item.Type | Should -Be 3
			$item.Version | Should -Be 1
			$item.Value | Should -Be "23"
			$item.Style | Should -Be "Default"
		}
		It "Should create a hybrid export" {
			Export-PSFConfig -Module Export-PSFConfig -Name TestPhase2.* -OutPath "TestDrive:\Export-PSFConfig.testB3.json"
			Test-Path "TestDrive:\Export-PSFConfig.testB3.json" | Should -Be $true
			$items = Get-Content "TestDrive:\Export-PSFConfig.testB3.json" | ConvertFrom-Json
			($items | Measure-Object).Count | Should -Be 3
			
			#region Simple Export
			$item = $items | Where-Object FullName -EQ 'Export-PSFConfig.TestPhase2.Settings1'
			$item.Version | Should -Be 1
			$item.Data | Should -Be 42
			$item.Data.GetType().FullName | Should -BeIn "System.Int32","System.Int64" # ConvertFrom-Json on later PS versions converts all numbers to long
			
			# Properties that only exist on non-simple export items
			$item.Style | Should -BeNullOrEmpty
			$item.Type | Should -BeNullOrEmpty
			$item.Value | Should -BeNullOrEmpty
			#endregion Simple Export
			
			#region Complex Export
			$item = $items | Where-Object FullName -EQ 'Export-PSFConfig.TestPhase2.Settings2'
			$item.Type | Should -Be 3
			$item.Version | Should -Be 1
			$item.Value | Should -Be "23"
			$item.Style | Should -Be "Default"
			#endregion Complex Export
		}
	}
	
	# Export under the ModuleName parameterset
	# - Only exports configuration items marked for module export
	# - Exports to the correct scopes' files
	# - Throws on a registry scope
	Describe "Ensuring Module Cache functionality works as designed" {
		BeforeAll {
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase3.Settings1 -Value 42 -ModuleExport -Initialize
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase3.Settings2 -Value 23
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase3.Settings3 -Value (Get-Date) -ModuleExport -Hidden -Initialize
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase3.Settings4 -Value "foo" -ModuleExport -Hidden -Initialize
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase3.Settings1 -Value 42
			Set-PSFConfig -FullName Export-PSFConfig.TestPhase3.Settings3 -Value (Get-Date)
			
			$module = Get-Module PSFramework | Sort-Object Version -Descending | Select-Object -First 1
			$pathFileUserLocal = & $module { $path_FileUserLocal }
			$pathFileUserShared = & $module { $path_FileUserShared }
			$pathFileSystem = & $module { $path_FileSystem }
		}
		
		It "Should only export configuration settings marked for export in the module cache" {
			Export-PSFConfig -ModuleName Export-PSFConfig
			Test-Path "$($pathFileUserShared)\export-psfconfig-1.json" | Should -Be $true
			
			$items = Get-Content "$($pathFileUserShared)\export-psfconfig-1.json" | ConvertFrom-Json
			($items | Measure-Object).Count | Should -Be 2 # Setting2 is not part of the cache, Setting4 has not yet been updated from default
			
			Remove-Item "$($pathFileUserShared)\export-psfconfig-1.json"
		}
		It "Should export to the scopes specified" {
			Test-Path "$($pathFileUserShared)\export-psfconfig-1.json" | Should -Be $false
			Export-PSFConfig -ModuleName Export-PSFConfig -Scope FileUserShared
			Test-Path "$($pathFileUserShared)\export-psfconfig-1.json" | Should -Be $true
			Remove-Item "$($pathFileUserShared)\export-psfconfig-1.json"
			
			Test-Path "$($pathFileUserLocal)\export-psfconfig-1.json" | Should -Be $false
			Export-PSFConfig -ModuleName Export-PSFConfig -Scope FileUserLocal
			Test-Path "$($pathFileUserLocal)\export-psfconfig-1.json" | Should -Be $true
			Remove-Item "$($pathFileUserLocal)\export-psfconfig-1.json"
			
			Test-Path "$($pathFileUserShared)\export-psfconfig-1.json" | Should -Be $false
			Test-Path "$($pathFileUserLocal)\export-psfconfig-1.json" | Should -Be $false
			Export-PSFConfig -ModuleName Export-PSFConfig -Scope FileUserShared, FileUserLocal
			Test-Path "$($pathFileUserShared)\export-psfconfig-1.json" | Should -Be $true
			Test-Path "$($pathFileUserLocal)\export-psfconfig-1.json" | Should -Be $true
			Remove-Item "$($pathFileUserShared)\export-psfconfig-1.json"
			Remove-Item "$($pathFileUserLocal)\export-psfconfig-1.json"
		}
		It "Should throw on registry scope" {
			{ Export-PSFConfig -ModuleName Export-PSFConfig -Scope UserDefault -EnableException } | Should -Throw
		}
	}
}