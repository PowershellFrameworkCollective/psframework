Describe "string config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.string'
        Set-PSFConfig -FullName $script:fullName -Value 'seed' -Validation 'string' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value 'hello world' -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 'hello world'
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value 12345 -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be '12345'
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value ([object]::new()) -EnableException 3>$null } | Should -Throw
    }
}
