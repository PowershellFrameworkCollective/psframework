Describe "integerpositive config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.integerpositive'
        Set-PSFConfig -FullName $script:fullName -Value 0 -Validation 'integerpositive' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value 3 -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 3
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value '8' -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 8
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value -1 -EnableException 3>$null } | Should -Throw
    }
}
