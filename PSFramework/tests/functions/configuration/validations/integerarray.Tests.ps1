Describe "integerarray config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.integerarray'
        Set-PSFConfig -FullName $script:fullName -Value @(0) -Validation 'integerarray' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value @([int]1, [int]2, [int]3) -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).Count | Should -Be 3
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value @('4', '5') -EnableException 3>$null } | Should -Not -Throw
        $value = Get-PSFConfigValue -FullName $script:fullName
        $value[0].GetType().FullName | Should -Be 'System.Int32'
        $value[0] | Should -Be 4
        $value[1] | Should -Be 5
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value @('one', 2) -EnableException 3>$null } | Should -Throw
    }
}
