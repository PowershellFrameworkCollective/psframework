Describe "datetime config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.datetime'
        Set-PSFConfig -FullName $script:fullName -Value ([datetime]'2000-01-01') -Validation 'datetime' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        $value = [datetime]'2024-12-31T12:34:56'
        { Set-PSFConfig -FullName $script:fullName -Value $value -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $value
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value '2026-02-03T04:05:06Z' -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).GetType().FullName | Should -Be 'System.DateTime'
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'not-a-date' -EnableException 3>$null } | Should -Throw
    }
}
