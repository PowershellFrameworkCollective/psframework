Describe "integer1to9 config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.integer1to9'
        Set-PSFConfig -FullName $script:fullName -Value 1 -Validation 'integer1to9' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value 4 -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 4
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value '9' -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 9
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 0 -EnableException 3>$null } | Should -Throw
    }
}
