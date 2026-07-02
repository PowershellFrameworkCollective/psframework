Describe "long config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.long'
        Set-PSFConfig -FullName $script:fullName -Value ([long]0) -Validation 'long' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value ([long]1234567890123) -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be ([long]1234567890123)
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value '9876543210' -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).GetType().FullName | Should -Be 'System.Int64'
        Get-PSFConfigValue -FullName $script:fullName | Should -Be ([long]9876543210)
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'abc' -EnableException 3>$null } | Should -Throw
    }
}
