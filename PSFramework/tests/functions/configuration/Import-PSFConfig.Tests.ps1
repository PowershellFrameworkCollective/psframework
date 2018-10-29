Describe "Import-PSFConfig Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module Import-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		Get-PSFConfig -FullName config.import.test | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	AfterAll {
		Get-PSFConfig -Module Import-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		Get-PSFConfig -FullName config.import.test | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Import-PSFConfig).ParameterSets.Name | Should -Be 'Path', 'ModuleName'
		foreach ($key in (Get-Command Import-PSFConfig).Parameters.Keys)
		{
			$key | Should -BeIn 'Path', 'ModuleName', 'ModuleVersion', 'Scope', 'IncludeFilter', 'ExcludeFilter', 'Peek', 'EnableException', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
		}
	}
	
	Describe "Integrity of imported data is verified" {
		# V1 Configuration imported correctly
		Set-Content -Path testdrive:\Import-PSFConfig.Phase1.Config1.json -Value @'
{
    "FullName":  "import-psfconfig.phase1.setting1",
    "Type":  3,
    "Version":  1,
    "Value":  "42",
    "Style":  "default"
}
'@
		It "Should correctly import the configuration Json from file" {
			Get-Content 'testdrive:\Import-PSFConfig.Phase1.Config1.json' | Select-String '"Version":  1' | Should -Not -BeNullOrEmpty
			Import-PSFConfig -Path testdrive:\Import-PSFConfig.Phase1.Config1.json
			Get-PSFConfigValue -FullName 'import-psfconfig.phase1.setting1' | Should -Be 42
			(Get-PSFConfigValue -FullName 'import-psfconfig.phase1.setting1').GetType().FullName | Should -Be 'System.Int32'
		}
		# Simple Export files imported correctly
		Set-Content -Path testdrive:\Import-PSFConfig.Phase1.Config2.json -Value @'
{
    "FullName":  "import-psfconfig.phase1.setting2",
    "Version":  1,
    "Data":  23
}
'@
		It "Should correctly import simple style configuration" {
			Import-PSFConfig -Path testdrive:\Import-PSFConfig.Phase1.Config2.json
			Get-PSFConfigValue -FullName 'import-psfconfig.phase1.setting2' | Should -Be 23
			(Get-PSFConfigValue -FullName 'import-psfconfig.phase1.setting2').GetType().FullName | Should -Be 'System.Int32'
		}
		# Deferred Deserialization applies
		Set-Content -Path testdrive:\Import-PSFConfig.Phase1.Config3.json -Value @'
{
    "FullName":  "import-psfconfig.phase1.setting3",
    "Type":  12,
    "Version":  1,
    "Value":  "H4sIAAAAAAAEAK1Xa2/iOBT9vtL+B5SvC3mQ8BREKmG6iwYomtAZaaYjrUnc4h0njmxnWvbXrx0g71DQDv1A8T0+ufa599iZPOz+Ya3PkDJEwqliqIaqq4bSegtwyKbKnvNorGnM28MAMDVAHiWMPHPVI4EWkVcxbw8x1rq6bmm6pdi//9ZqTQRn6xN8XvhTRT8OicHtujImR233wDgM1MWDOkcUepzQwyJ8JhNtW4+6RxgefzXDVkDkBfDsIJ4okhGs9bhyTPy3TvMlLqcofLG/oNAnr0zEziMnxIaSiGWsbms9VdYggEo2xS2F72OMjxBn/NSI2gAKQ67YhchMRj68IcaZYnMaw4k2K837RAhPmKuUH944DKXGJdb5VkYdCgEXwS2SqXV1Y9DRR53uaGvoY6s3Ngx1MDCHA9P6Q++OdX2izbeXKB65V2DRh0WWr3UES8D4nedBxtIshh190DH6MgvdGutDtav3h9Zg1JxFkeScx5lH5FHgaczjC0Uc/s80Uo4bs0jkuuOi0nYxh0LrtC0y4SZavvYmq0oBuRvA94q9Svt1I3vVlb2qOoTCp6yLxuOLpegei/FGvjoiZ4+w39wf0jQS3Jyin1A5m4WRmUXBRArjxd4PwQsMRM7qXcxJkFSleqItW8ZlOyhZQtEWnIoh1JhCtn4npnIfl8RLEiq2Ydk/nPqg4P6JfEivE6Keo9YjsvAcMo+i6Jjig1sBrRGWsBV4Q0EcuOhfoZRWhJyEFIbgiwUjgFMtu0XNCnpWYtdomj2jLOr7wtaIWxT4lmdXC6GhGPKb+MggTfQu7WAeswGMvRLqVzFFDziPiZXWCjZHLMLgkKhfoKrS5O0k+f3Yt07p+optdM2ROdSH/ZHRnWgiVIu9p1CUsWHqo65umUbf6JexEy3vWoW8MytIC/5cJWaDG5g3usGJ9xfawXUdeYtjLIIIJ5kL/PYQwcauDwIQ+ix3MTovr77F/4I4kljl8h75GHckVBVXwUte9Z7hbFw3BNEivGBa9RNXxI8xPD7k+qlng0omV7yp6nH1z3ZABHYII47kCSyWyCFtt9w9ibEvdldeMNqtzAFYw06T001Pdjp7uqcI+hR5+wr6VPDJEcXSYrcu2GUlli9ch2AsKlesj52KWGwHxLnxv41v3649L8W6LyDb6cuDKd4cxJ/YlxjzmMJpCGNOAW63NvEOI+8jPGzJDyiAxu7ZHPb6wDf7FjR737//OvdeujVMYs+ya0Od2br2vKyJpC+Tle217J0lG5sdy3/BHBJygEJ5cNdf3KU8iu135Kd6dZoBBt+9N20BfYE8rZ1eg1H2mowyXzN/QpEr8tSleNnIVcrRutqtgHmEYrTLpLeulX43GICe1+sbI9OC+nBUlf42+xUK5fQs7f/JCpYo/JH4Z4pMz57zhOSb2f8BpzdzLA0PAAA=",
    "Style":  "Default"
}
'@
		It "Should correctly defer deserialization until being explicitly requested" {
			Import-PSFConfig -Path testdrive:\Import-PSFConfig.Phase1.Config3.json
			(Get-PSFConfig -FullName 'Import-PSFConfig.Phase1.Setting3').SafeValue.Name | Should -BeNullOrEmpty
			(Get-PSFConfig -FullName 'Import-PSFConfig.Phase1.Setting3').Value.Name | Should -Be 'Windows'
		}
	}
	Describe "Import paths / methodologies are applied" {
		# Import from Weblink works correctly
		It "Should correctly import configuration from a weblink" {
			$webLink = 'https://raw.githubusercontent.com/PowershellFrameworkCollective/psframework/master/PSFramework/tests/testdata/configdata.json'
			Get-PSFConfigValue -FullName 'config.import.test' | Should -BeNullOrEmpty
			{ Import-PSFConfig -Path $webLink -ErrorAction Stop -EnableException } | Should -Not -Throw
			Get-PSFConfigValue -FullName 'config.import.test' | Should -Be 42
		}
		
		# Import from raw json works correctly
		It "Should correctly import raw json data for configuration" {
			$json = @'
{
    "FullName":  "import-psfconfig.phase2.setting1",
    "Type":  3,
    "Version":  1,
    "Value":  "42",
    "Style":  "Default"
}
'@
			{ $json | Import-PSFConfig } | Should -Not -Throw
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting1' | Should -Be 42
		}
		# Peek works
		It "Should allow peek at settings without importing them" {
			$json = @'
{
    "FullName":  "import-psfconfig.phase2.setting2",
    "Type":  3,
    "Version":  1,
    "Value":  "42",
    "Style":  "Default"
}
'@
			$data = $json | Import-PSFConfig -Peek
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting2' | Should -BeNullOrEmpty
			$data.FullName | Should -Be 'import-psfconfig.phase2.setting2'
			$data.Value | Should -Be 42
			$data.KeepPersisted | Should -Be $false
		}
		# Include Filter & Exclude Filters apply
		It "Should correctly filter out unwanted settings" {
			#region Raw Json
			$json1 = @'
[
    {
        "FullName":  "import-psfconfig.phase2.setting3",
        "Type":  3,
        "Version":  1,
        "Value":  "3",
        "Style":  "Default"
    },
    {
        "FullName":  "import-psfconfig.phase2.setting4",
        "Type":  3,
        "Version":  1,
        "Value":  "4",
        "Style":  "Default"
    },
    {
        "FullName":  "import-psfconfig.phase2.setting8",
        "Type":  3,
        "Version":  1,
        "Value":  "8",
        "Style":  "Default"
    }
]
'@
			$json2 = @'
[
    {
        "FullName":  "import-psfconfig.phase2.setting7",
        "Type":  3,
        "Version":  1,
        "Value":  "7",
        "Style":  "Default"
    },
    {
        "FullName":  "import-psfconfig.phase2.setting10",
        "Type":  3,
        "Version":  1,
        "Value":  "10",
        "Style":  "Default"
    },
    {
        "FullName":  "import-psfconfig.phase2.setting9",
        "Type":  3,
        "Version":  1,
        "Value":  "9",
        "Style":  "Default"
    },
    {
        "FullName":  "import-psfconfig.phase2.setting5",
        "Type":  3,
        "Version":  1,
        "Value":  "5",
        "Style":  "Default"
    },
    {
        "FullName":  "import-psfconfig.phase2.setting6",
        "Type":  3,
        "Version":  1,
        "Value":  "6",
        "Style":  "Default"
    }
]
'@
			#endregion Raw Json 
			
			{ $json1 | Import-PSFConfig -IncludeFilter 'import-psfconfig.phase2.setting3', 'import-psfconfig.phase2.setting4' } | Should -Not -Throw
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting3' | Should -Be 3
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting4' | Should -Be 4
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting8' | Should -BeNullOrEmpty
			
			{ $json2 | Import-PSFConfig -ExcludeFilter 'import-psfconfig.phase2.setting5', 'import-psfconfig.phase2.setting6', 'import-psfconfig.phase2.setting7' } | Should -Not -Throw
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting5' | Should -BeNullOrEmpty
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting6' | Should -BeNullOrEmpty
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting7' | Should -BeNullOrEmpty
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting9' | Should -Be 9
			Get-PSFConfigValue -FullName 'import-psfconfig.phase2.setting10' | Should -Be 10
		}
	}
	Describe "The module cache feature import is working as designed" {
		$module = Get-Module PSFramework | Sort-Object Version -Descending | Select-Object -First 1
		$pathFileUserLocal = & $module { $path_FileUserLocal }
		$pathFileUserShared = & $module { $path_FileUserShared }
		$pathFileSystem = & $module { $path_FileSystem }
		
		$json1 = @'
{
    "FullName":  "Import-PSFConfig.phase3.Setting1",
    "Type":  3,
    "Version":  1,
    "Value":  "42",
    "Style":  "Default"
}
'@
		$json2 = @'
{
    "FullName":  "Import-PSFConfig.phase3.Setting2",
    "Type":  3,
    "Version":  1,
    "Value":  "23",
    "Style":  "Default"
}
'@
		Set-Content -Path "$($pathFileUserLocal)\import-psfconfig-1.json" -Value $json1
		Set-Content -Path "$($pathFileUserShared)\import-psfconfig-1.json" -Value $json2
		
		# Import module cache works
		It "Should import cached settings from the module cache" {
			Import-PSFConfig -ModuleName 'Import-PSFConfig'
			Get-PSFConfigValue 'import-psfconfig.phase3.setting1' | Should -Be 42
			Get-PSFConfigValue 'import-psfconfig.phase3.setting2' | Should -Be 23
		}
	}
}