Describe "double config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.double'
        Set-PSFConfig -FullName $script:fullName -Value ([double]0.5) -Validation 'double' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value ([double]3.25) -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 3.25
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value '2.75' -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).GetType().FullName | Should -Be 'System.Double'
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 2.75
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'abc' -EnableException 3>$null } | Should -Throw
    }
}
