Describe "integer0to9 config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.integer0to9'
        Set-PSFConfig -FullName $script:fullName -Value 0 -Validation 'integer0to9' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value 5 -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 5
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value '7' -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 7
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 10 -EnableException 3>$null } | Should -Throw
    }
}
