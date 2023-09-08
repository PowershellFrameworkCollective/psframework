Describe "Import-PSFConfig Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	BeforeAll {
		Get-PSFConfig -Module Import-PSFConfig -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		Get-PSFConfig -FullName config.import.test | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		Get-PSFConfig -FullName MetaJson | ForEach-Object {
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
		Get-PSFConfig -FullName MetaJson | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Import-PSFConfig).ParameterSets.Name | Should -Be 'Path', 'ModuleName', 'Environment'
		foreach ($key in (Get-Command Import-PSFConfig).Parameters.Keys)
		{
			$key | Should -BeIn 'Path', 'ModuleName', 'ModuleVersion', 'Scope', 'Schema', 'IncludeFilter', 'ExcludeFilter', 'Peek', 'AllowDelete', 'PassThru', 'EnvironmentPrefix', 'Simple', 'EnableException', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
		}
	}
	
	Describe "Integrity of imported data is verified" {
		BeforeAll {
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
			
			# Simple Export files imported correctly
			Set-Content -Path testdrive:\Import-PSFConfig.Phase1.Config2.json -Value @'
{
    "FullName":  "import-psfconfig.phase1.setting2",
    "Version":  1,
    "Data":  23
}
'@
			
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
		}
		
		It "Should correctly import the configuration Json from file" {
			Get-Content 'testdrive:\Import-PSFConfig.Phase1.Config1.json' | Select-String '"Version":  1' | Should -Not -BeNullOrEmpty
			Import-PSFConfig -Path testdrive:\Import-PSFConfig.Phase1.Config1.json
			Get-PSFConfigValue -FullName 'import-psfconfig.phase1.setting1' | Should -Be 42
			(Get-PSFConfigValue -FullName 'import-psfconfig.phase1.setting1').GetType().FullName | Should -BeIn "System.Int32","System.Int64" # ConvertFrom-Json on later PS versions converts all numbers to long
		}
		
		It "Should correctly import simple style configuration" {
			Import-PSFConfig -Path testdrive:\Import-PSFConfig.Phase1.Config2.json
			Get-PSFConfigValue -FullName 'import-psfconfig.phase1.setting2' | Should -Be 23
			(Get-PSFConfigValue -FullName 'import-psfconfig.phase1.setting2').GetType().FullName | Should -BeIn "System.Int32","System.Int64" # ConvertFrom-Json on later PS versions converts all numbers to long
		}
		
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
		BeforeAll {
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
		}
		
		# Import module cache works
		It "Should import cached settings from the module cache" {
			Import-PSFConfig -ModuleName 'Import-PSFConfig'
			Get-PSFConfigValue 'import-psfconfig.phase3.setting1' | Should -Be 42
			Get-PSFConfigValue 'import-psfconfig.phase3.setting2' | Should -Be 23
		}
	}
	
	# MetaJson Configuration Schema Validation
	Describe "Imports successfully MetaJson Schema Configuration" {
		BeforeAll {
			#region Json Configuration Files
			$json1 = @'
{
    "ModuleName":  "MetaJson",
    "Version":  1,
    "Static":  {
                   "Setting1":  42
               },
    "Object":  {
                   "Setting3":  "H4sIAAAAAAAEALVXW2/iOBh9X2n/A8oz5ELCVYBUYLqLBiia0Blp20prErd468SR7UzL/vp1EkIS4gTa1bRSC/b5rj4+tkd3u39Y4zukDBF/rBiqoeqqoTTePeyzsbLnPBhqGnP20ANM9ZBDCSPPXHWIpwXkTdjtIcZaW9ctTbeUye+/NRoj4bPxDT4v3LGiJ0NicLsujUWjE/vAOPRUYQMd/vA00raS2RtKwUE+lRhmc+LTOv24tHMWuayMLINCZoXxfJDFnTpHVMQh9LDwn0k+lRLyFmGYfKuHroDoHsDTg4h+XsWlKs8qTcDE5hT5L5M77Iq59FsOsaEkYMUIdmM9VtbAg0piZkumb0OME8hs+CiyCR4roRtAoc+VSYQqIaYR4ss7YpwJBA3hSJtKfHwjhMeh5CG+vHPoR3RVJiXAfBshZhQCLgBbFOXc1o1BS2+3DHNr6EO9N+x01W7P7LQH7ZbeH+r6SJtvL7m5507RU7/o6a8qJ0vA+I3jQMak2fSHlq6a/V67N6hPpuhHlk7OVW02Pyji8P8nc3Lz8VziZbzhgp67kEPBhdPeKi7oSDsn7GglJZ29AXyvTFYnedpE0mRH0qTOCIWP2ZYcDi9z2E5Y/AmnVQ5ne4Td6l0WSVOMm1P0EyqpHLWLclSQqtJcUVl88AI9UYN6E3LixTRWj+5lolQ0l4tRSXASo1RmZlLJiTFl2cl6Mwtp1OslceIk5cqRwY8yJAWkXaTkJ3IhPbXRLLcqcnfVykoDaSJSRX6V2pVB5pA5FAVJtXf2HLFXKXiNcARfgXfkhZ6N/hXE0CqrFmLlij4igE91W9K6MwpJ+3INjbJYMh4VfVRxKWlkiU+Jccqjj+Qh517sT86/fJPvGaQxtSQdzuM2gLE3Ql05rqxX6biUMEefggABBoeYOSW3cpfnMhiP3XetYymuMrHMjt4x+33THLRHmpiqxN9SKHZUp9+zjG6va4m/MvxIO1feUk2ZipV2YKdGyCQsvcjAo/9fpGTX6cJnxG7hBTiuRthtDwGsPF08D/guy90k05KrZeVPiIMIr9T3zsW4FUFVccO/JLMXZPB4ttk+CBZ+zUFZbbwibohhEuxj5qk4xg6kuljW2uo8ZiAAO4QRR9FtRJTNIW027D0JsSs6H926mo1MbVjNKpDjNTlSFPb4TN8g8j1Qd17FhzI77ZXuBdUu7aUUka77jGAsSC9KZkf+iy5BnBv/23h4uPamINpQg2yeno6meDeKX9GmEPOQwrEPQ04BbjY24Q4j5ys8bMkrFEBj92z2O13gml0Lmp2np19ziOTffoUJ0cfsElWh4zJjmYrL5FmijNNkpyzYjPgcIF9IY837J1ouZeK2oh/5hXIKGLx4m9wC+gL5iVe9Gg2WcE7Opz+gyB056lK84XIsSpSw2fCYQyhGu4wW1rW02PV6oON0usbAtKDeH8hp8TllF6t5ts6SNToqyhL5r7E0FywKx1/eOKNKOhr/Z5P/ANjaD5pZEQAA"
               },
    "Dynamic":  {
                    "Setting2":  "Foo: %COMPUTERNAME%"
                }
}
'@
			$json2 = @'
{
    "Version":  1,
    "Static":  {
                   "MetaJson.Setting4":  42
               },
    "Object":  {
                   "MetaJson.Setting5":  "H4sIAAAAAAAEALVXW2/iOBh9X2n/A8oz5ELCVYBUYLqLBiia0Blp20prErd468SR7UzL/vp1EkIS4gTa1bRSC/b5rj4+tkd3u39Y4zukDBF/rBiqoeqqoTTePeyzsbLnPBhqGnP20ANM9ZBDCSPPXHWIpwXkTdjtIcZaW9ctTbeUye+/NRoj4bPxDT4v3LGiJ0NicLsujUWjE/vAOPRUYQMd/vA00raS2RtKwUE+lRhmc+LTOv24tHMWuayMLINCZoXxfJDFnTpHVMQh9LDwn0k+lRLyFmGYfKuHroDoHsDTg4h+XsWlKs8qTcDE5hT5L5M77Iq59FsOsaEkYMUIdmM9VtbAg0piZkumb0OME8hs+CiyCR4roRtAoc+VSYQqIaYR4ss7YpwJBA3hSJtKfHwjhMeh5CG+vHPoR3RVJiXAfBshZhQCLgBbFOXc1o1BS2+3DHNr6EO9N+x01W7P7LQH7ZbeH+r6SJtvL7m5507RU7/o6a8qJ0vA+I3jQMak2fSHlq6a/V67N6hPpuhHlk7OVW02Pyji8P8nc3Lz8VziZbzhgp67kEPBhdPeKi7oSDsn7GglJZ29AXyvTFYnedpE0mRH0qTOCIWP2ZYcDi9z2E5Y/AmnVQ5ne4Td6l0WSVOMm1P0EyqpHLWLclSQqtJcUVl88AI9UYN6E3LixTRWj+5lolQ0l4tRSXASo1RmZlLJiTFl2cl6Mwtp1OslceIk5cqRwY8yJAWkXaTkJ3IhPbXRLLcqcnfVykoDaSJSRX6V2pVB5pA5FAVJtXf2HLFXKXiNcARfgXfkhZ6N/hXE0CqrFmLlij4igE91W9K6MwpJ+3INjbJYMh4VfVRxKWlkiU+Jccqjj+Qh517sT86/fJPvGaQxtSQdzuM2gLE3Ql05rqxX6biUMEefggABBoeYOSW3cpfnMhiP3XetYymuMrHMjt4x+33THLRHmpiqxN9SKHZUp9+zjG6va4m/MvxIO1feUk2ZipV2YKdGyCQsvcjAo/9fpGTX6cJnxG7hBTiuRthtDwGsPF08D/guy90k05KrZeVPiIMIr9T3zsW4FUFVccO/JLMXZPB4ttk+CBZ+zUFZbbwibohhEuxj5qk4xg6kuljW2uo8ZiAAO4QRR9FtRJTNIW027D0JsSs6H926mo1MbVjNKpDjNTlSFPb4TN8g8j1Qd17FhzI77ZXuBdUu7aUUka77jGAsSC9KZkf+iy5BnBv/23h4uPamINpQg2yeno6meDeKX9GmEPOQwrEPQ04BbjY24Q4j5ys8bMkrFEBj92z2O13gml0Lmp2np19ziOTffoUJ0cfsElWh4zJjmYrL5FmijNNkpyzYjPgcIF9IY837J1ouZeK2oh/5hXIKGLx4m9wC+gL5iVe9Gg2WcE7Opz+gyB056lK84XIsSpSw2fCYQyhGu4wW1rW02PV6oON0usbAtKDeH8hp8TllF6t5ts6SNToqyhL5r7E0FywKx1/eOKNKOhr/Z5P/ANjaD5pZEQAA"
               },
    "Dynamic":  {
                    "MetaJson.Setting6":  "Foo: %COMPUTERNAME%"
                }
}
'@
			$json3 = @'
{
    "Static":  {
                   "Setting7":  42
               },
    "ModuleName":  "MetaJson",
    "Include":  [
                     ".\\MetaJson.include1.json",
                     ".\\%COMPUTERNAME%\\MetaJson.include2.json"
                 ],
    "Version":  1
}
'@
			$json4 = @'
{
    "Static":  {
                   "Setting7":  23
               },
    "ModuleName":  "MetaJson",
    "Version":  1
}
'@
			$json5 = @'
{
    "Dynamic":  {
                   "%COMPUTERNAME%":  7
                },
    "ModuleName":  "MetaJson",
    "Version":  1
}
'@
			Set-Content -Value $json1 -Path 'testdrive:\MetaJson1.json'
			Set-Content -Value $json2 -Path 'testdrive:\MetaJson2.json'
			Set-Content -Value $json3 -Path 'testdrive:\MetaJson3.json'
			Set-Content -Value $json4 -Path 'testdrive:\MetaJson.include1.json'
			$null = New-Item -Path 'testdrive:\' -Name $env:COMPUTERNAME -ItemType Directory
			Set-Content -Value $json5 -Path "testdrive:\$($env:COMPUTERNAME)\MetaJson.include2.json"
			#endregion Json Configuration Files
		}
		
		It "Should import a plain file import with Modulename correctly" {
			{ Import-PSFConfig -Path 'testdrive:\MetaJson1.json' -Schema MetaJson -EnableException } | Should -Not -Throw
			Get-PSFConfigValue -FullName MetaJson.Setting1 | Should -Be 42
			Get-PSFConfigValue -FullName MetaJson.Setting2 | Should -Be "Foo: $env:COMPUTERNAME"
			(Get-PSFConfigValue -FullName MetaJson.Setting3).Name | Should -Be 'Old'
		}
		
		It "Should import a plain file import without Modulename correctly" {
			{ Import-PSFConfig -Path 'testdrive:\MetaJson2.json' -Schema MetaJson -EnableException } | Should -Not -Throw
			Get-PSFConfigValue -FullName MetaJson.Setting4 | Should -Be 42
			Get-PSFConfigValue -FullName MetaJson.Setting6 | Should -Be "Foo: $env:COMPUTERNAME"
			(Get-PSFConfigValue -FullName MetaJson.Setting5).Name | Should -Be 'Old'
		}
		
		It "Should import a file with include files correctly" {
			{ Import-PSFConfig -Path 'testdrive:\MetaJson3.json' -Schema MetaJson -EnableException } | Should -Not -Throw
			Get-PSFConfigValue -FullName MetaJson.Setting7 | Should -Be 23
			Get-PSFConfigValue -FullName "MetaJson.$($env:COMPUTERNAME)" | Should -Be 7
		}
	}
}