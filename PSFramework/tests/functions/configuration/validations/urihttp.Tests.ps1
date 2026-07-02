Describe "urihttp config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.urihttp'
        Set-PSFConfig -FullName $script:fullName -Value 'https://example.com' -Validation 'urihttp' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value 'http://contoso.com/path' -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 'http://contoso.com/path'
    }

    It "accepts values that require conversion" {
        $uriObject = [uri]'https://fabrikam.com/service'
        { Set-PSFConfig -FullName $script:fullName -Value $uriObject -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 'https://fabrikam.com/service'
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'ftp://contoso.com/path' -EnableException 3>$null } | Should -Throw
    }
}
