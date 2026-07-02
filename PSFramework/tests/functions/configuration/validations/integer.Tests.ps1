Describe "integer config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.integer'
        Set-PSFConfig -FullName $script:fullName -Value 0 -Validation 'integer' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value 42 -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 42
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value '17' -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).GetType().FullName | Should -Be 'System.Int32'
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 17
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'abc' -EnableException 3>$null } | Should -Throw
    }
}
