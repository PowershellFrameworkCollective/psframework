Describe "guid config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.guid'
        Set-PSFConfig -FullName $script:fullName -Value ([guid]::Empty) -Validation 'guid' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        $value = [guid]::NewGuid()
        { Set-PSFConfig -FullName $script:fullName -Value $value -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $value
    }

    It "accepts values that require conversion" {
        $value = [guid]::NewGuid()
        { Set-PSFConfig -FullName $script:fullName -Value $value.Guid -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $value
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'not-a-guid' -EnableException 3>$null } | Should -Throw
    }
}
