Describe "Set-PSFConfig Unit Tests" -Tag "CI","Config","Unit" {
	BeforeAll {
		Get-PSFConfig -Module PSFTests -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		$global:handler = "Did not run"
	}
	AfterAll {
		Get-PSFConfig -Module PSFTests -Force | ForEach-Object {
			$null = [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove($_.FullName)
		}
		
		Remove-Variable -Scope Global -Name handler
	}
	
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Set-PSFConfig).ParameterSets.Name | Should -Be 'FullName', 'Persisted', 'Module'
		(Get-Command Set-PSFConfig).Parameters.Keys | Should -Be 'FullName', 'Module', 'Name', 'Value', 'PersistedValue', 'PersistedType', 'Description', 'Validation', 'Handler', 'Hidden', 'Default', 'Initialize', 'SimpleExport', 'ModuleExport', 'AllowDelete', 'DisableValidation', 'DisableHandler', 'PassThru', 'EnableException', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
	}
	
	Describe "Basic functionality tests" {
		It "Should set a simple setting without issues" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Value "foo"
			Get-PSFConfigValue -FullName 'PSFTests.Set-PSFConfig.Test1' | Should -Be "foo"
		}
		
		It "Should initialize the setting without changing its current value" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Value "bar" -Initialize
			Get-PSFConfigValue -FullName 'PSFTests.Set-PSFConfig.Test1' | Should -Be "foo"
		}
		
		It "Should correctly apply individual settings" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Description "foo"
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1').Description | Should -Be "foo"
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Handler { "foo" }
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1').Handler | Should -Be ' "foo" '
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Validation "string"
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1').Validation | Should -Be ([PSFramework.Configuration.ConfigurationHost]::Validation["string"])
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Hidden
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Force).Hidden | Should -Be $true
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -SimpleExport
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Force).SimpleExport | Should -Be $true
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -ModuleExport
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Force).ModuleExport | Should -Be $true
		}
		
		It "Should correctly pass through items with -PassThru" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Description "foo2" -PassThru | Should -Be (Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test1' -Force)
		}
	}
	
	Describe "Initialization tests" {
		It "Initializing a setting should flag the setting and not run handlers" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test2' -Value $true -Initialize -Validation "bool" -Handler { $global:handler = "Handler" } -Description "Dummy Text" -SimpleExport -ModuleExport -PassThru
			$config.Initialized | Should -Be $true
			$global:handler | Should -Be "Did not run"
		}
		
		It "Initializing a setting should flag the setting and not run validation on default settings, even though they are bad" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test3' -Value "foo" -Initialize -Validation "bool" -Handler { $global:handler = "Handler" } -Description "Dummy Text" -SimpleExport -ModuleExport -PassThru
			$config.Initialized | Should -Be $true
			$config.Value | Should -Be "foo"
		}
		
		It "Initializing a setting should run validation on previous setting" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test4' -Value "foo"
			{ Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test4' -Value $true -Initialize -Validation "bool" -Handler { $global:handler = "Handler" } -EnableException 3>$null } | Should -Throw
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test4').Value | Should -Be $true
			(Get-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test4').Value.GetType().FullName | Should -Be "System.Boolean"
			$global:handler | Should -Be "Did not run"
		}
		
		It "Initializing a setting should run handler on previous setting" {
			$global:handler | Should -Be "Did not run"
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test5' -Value "bar"
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test5' -Value "foo" -Initialize -Handler { $global:handler = "Handler" } -PassThru
			$config.Value | Should -Be "bar"
			$config.Initialized | Should -Be $true
			$global:handler | Should -Be "Handler"
		}
	}
	
	Describe "Odds & Sods" {
		It "Should properly parse Module and name" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test6' -Value "bar" -PassThru
			$config.Module | Should -Be "psftests"
			$config.Name | Should -Be "set-psfconfig.test6"
		}
		
		It "Should skip validation when ordered to" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test7' -Value $true -Validation "bool"
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test7' -Value "foo" -DisableValidation -PassThru
			$config.Value | Should -Be "foo"
		}
		
		It "Should skip handler when ordered to" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test8' -Value $true -Handler { $global:handler = "Handler2" }
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test8' -Value $false -DisableHandler
			$global:handler | Should -Not -Be "Handler2"
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test8' -Value $true
			$global:handler | Should -Be "Handler2"
		}
		
		It "Should properly process simple persisted data" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test9' -PersistedValue "true" -PersistedType "bool" -PassThru
			$config.SafeValue | Should -Be $true
			$config.SafeValue.GetType() | Should -Be ([bool])
			$config.Value | Should -Be $true
		}
		
		It "Should properly process complex persisted data" {
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test10' -PersistedValue "H4sIAAAAAAAEAK2XXY/iNhSG7yv1P0S5Xcg3EFCINMBMiwos2jCt1GWlmsQzuOvEyHZ2h/76OgES8jmgXeaCwX59fOzz+onjfNz9y6Q/IWWIRGNZV3RFU3RZegtxxMbynvPDSFWZv4chYEqIfEoYeeGKT0L1QL6LcXuIsWpomqVqluz++oskOSKm9Am+zIOxrJ2aRONmVWlLWl3vyDgMlflHZYYo9Dmhx3n0Qhx1U696QhiefjXLlkDkBfDkKGYUyYio9bpyn/hvleVLPE5R9OpOR9tnJha6faIIBhT5+60SEB5BvhX6i+o8ak3JgeUzedJqLK9ACGX3PMZRvVL3U4zxSdI6U3nYGlAYcdnNtAXJJJE8viHGmexyGkNHnZQCfCKEp3NWYz++cRgljpDdQudsk/ROKQRcdG5QkrSh6YOubnQNe6PbI90c6T1FN4eaYdgfNH2kaY4627SFeOZ+McqgGOXvugALwPiD70PGsizsrmZ1DXOja6Nef2T2lYE50HVj+EEzGrIoBrnkcYmj2cU4jXn8RRGHP5hGFuPOLNJyPXDhwV3Moah1dojywjnqtSudZcVJ3hrwvewus9O9Tk62l5xsZUoo3OZnbjS6z6TeyaY/NkFd3Oke4aD5ZCUISnUzir5B+YIePUdPAUmF9iJJIvAKQ7EE5SHmJExdq5zDlgHUDpcSYEqQqaCkBif5+qcxTbZ1Qfw0Idlt2bEyiKb1nWKqbyiA9LYy1ceoRUrePYPMp+jAK2BJJSuEE9ESvKEwDj30nyibWpScqyroEYjVI4CzwhrFAhaKW+m7pcD5HOUKv1/lmkoXq33P3FVXNDjjehMTO6TVLu3gtWYNGPtOaFDVFIFxaRMrrS3YDLEDBse09oVQ1TDX7El/P/etc7qB7OqGNhxYpmUbtu2ooqtW+0QhTLS2Zdq23bcSpha1jnqNuELeORcyu19cYjagwbwTDee4P5ENt53He/AxDw84zVzoN8cDbDzzYQiigF3duS7Lqz/gv0N8SLRy+x4FGHcTqSJumW2keg83a8+LwGEetSCrfuCSBDGGp0luH3oBVDq4wqYbCHdCNziAHcKIo+RxLZbIIe1I3p7EOBC7m9xGOlJOANaw06T+wlhRnw2fPq9YZnarBZeVvmvjTgnGwrlifexsYrEdEF+1/6N//nzrw1Osu0XZyd5LTPFSIv7EvsSYxxSOIxhzCnBHWsc7jPw/4HFDvkIh1Hcvpt3rg8DsW9Dsffny8+i98GoiiT3L7xB1sPXcx3JNzu1PDe2zarujlicv47jM2hL2JqfjMmdTEnGAouQxX/9WkJRTdoNu8qneuyaAwXcvXRtAXyHPvNZrAGuvCazXHvsNilyRryzEm8yVs06o60gh8wnFaJdbxbrVKrvBAPT8Xl8fmhbU7GHVKvfhulIhr+V9rljiYnlLpTtTZ4GirymqM5Nlj7nLgPSbuf8Dx70zndMPAAA=" -PersistedType "object" -PassThru
			$config.SafeValue | Should -Be "H4sIAAAAAAAEAK2XXY/iNhSG7yv1P0S5Xcg3EFCINMBMiwos2jCt1GWlmsQzuOvEyHZ2h/76OgES8jmgXeaCwX59fOzz+onjfNz9y6Q/IWWIRGNZV3RFU3RZegtxxMbynvPDSFWZv4chYEqIfEoYeeGKT0L1QL6LcXuIsWpomqVqluz++oskOSKm9Am+zIOxrJ2aRONmVWlLWl3vyDgMlflHZYYo9Dmhx3n0Qhx1U696QhiefjXLlkDkBfDkKGYUyYio9bpyn/hvleVLPE5R9OpOR9tnJha6faIIBhT5+60SEB5BvhX6i+o8ak3JgeUzedJqLK9ACGX3PMZRvVL3U4zxSdI6U3nYGlAYcdnNtAXJJJE8viHGmexyGkNHnZQCfCKEp3NWYz++cRgljpDdQudsk/ROKQRcdG5QkrSh6YOubnQNe6PbI90c6T1FN4eaYdgfNH2kaY4627SFeOZ+McqgGOXvugALwPiD70PGsizsrmZ1DXOja6Nef2T2lYE50HVj+EEzGrIoBrnkcYmj2cU4jXn8RRGHP5hGFuPOLNJyPXDhwV3Moah1dojywjnqtSudZcVJ3hrwvewus9O9Tk62l5xsZUoo3OZnbjS6z6TeyaY/NkFd3Oke4aD5ZCUISnUzir5B+YIePUdPAUmF9iJJIvAKQ7EE5SHmJExdq5zDlgHUDpcSYEqQqaCkBif5+qcxTbZ1Qfw0Idlt2bEyiKb1nWKqbyiA9LYy1ceoRUrePYPMp+jAK2BJJSuEE9ESvKEwDj30nyibWpScqyroEYjVI4CzwhrFAhaKW+m7pcD5HOUKv1/lmkoXq33P3FVXNDjjehMTO6TVLu3gtWYNGPtOaFDVFIFxaRMrrS3YDLEDBse09oVQ1TDX7El/P/etc7qB7OqGNhxYpmUbtu2ooqtW+0QhTLS2Zdq23bcSpha1jnqNuELeORcyu19cYjagwbwTDee4P5ENt53He/AxDw84zVzoN8cDbDzzYQiigF3duS7Lqz/gv0N8SLRy+x4FGHcTqSJumW2keg83a8+LwGEetSCrfuCSBDGGp0luH3oBVDq4wqYbCHdCNziAHcKIo+RxLZbIIe1I3p7EOBC7m9xGOlJOANaw06T+wlhRnw2fPq9YZnarBZeVvmvjTgnGwrlifexsYrEdEF+1/6N//nzrw1Osu0XZyd5LTPFSIv7EvsSYxxSOIxhzCnBHWsc7jPw/4HFDvkIh1Hcvpt3rg8DsW9Dsffny8+i98GoiiT3L7xB1sPXcx3JNzu1PDe2zarujlicv47jM2hL2JqfjMmdTEnGAouQxX/9WkJRTdoNu8qneuyaAwXcvXRtAXyHPvNZrAGuvCazXHvsNilyRryzEm8yVs06o60gh8wnFaJdbxbrVKrvBAPT8Xl8fmhbU7GHVKvfhulIhr+V9rljiYnlLpTtTZ4GirymqM5Nlj7nLgPSbuf8Dx70zndMPAAA="
			$config.SafeValue.GetType() | Should -Be ([string])
			$config.Value.Name | Should -Be ".dotnet"
			# Once the value property has been accessed, the SafeValue should too be accessible
			$config.SafeValue.Name | Should -Be ".dotnet"
		}
		
		It "Should respect values when setting default values" {
			Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test11' -Value "foo"
			$config = Set-PSFConfig -FullName 'PSFTests.Set-PSFConfig.Test11' -Value "bar" -Default -PassThru
			$config.Value | Should -Be "foo"
		}
	}
}