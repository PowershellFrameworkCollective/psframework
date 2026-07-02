Describe "psframework.logfilefiletype config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.psframework.logfilefiletype'
        $script:enumNames = [enum]::GetNames([PSFramework.Logging.LogFileFileType])
        Set-PSFConfig -FullName $script:fullName -Value $script:enumNames[0] -Validation 'psframework.logfilefiletype' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        $value = [PSFramework.Logging.LogFileFileType]$script:enumNames[0]
        { Set-PSFConfig -FullName $script:fullName -Value $value -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $value
    }

    It "accepts values that require conversion" {
        $convertedName = if ($script:enumNames.Count -gt 1) { $script:enumNames[1] } else { $script:enumNames[0] }
        $expected = [PSFramework.Logging.LogFileFileType]$convertedName
        { Set-PSFConfig -FullName $script:fullName -Value $convertedName -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $expected
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'not-a-logfile-type' -EnableException 3>$null } | Should -Throw
    }
}
