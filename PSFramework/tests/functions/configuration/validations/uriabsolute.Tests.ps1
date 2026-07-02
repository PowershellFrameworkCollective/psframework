Describe "uriabsolute config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.uriabsolute'
        Set-PSFConfig -FullName $script:fullName -Value 'https://example.com' -Validation 'uriabsolute' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value 'https://contoso.com/path' -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 'https://contoso.com/path'
    }

    It "accepts values that require conversion" {
        $uriObject = [uri]'https://fabrikam.com/service'
        { Set-PSFConfig -FullName $script:fullName -Value $uriObject -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 'https://fabrikam.com/service'
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value '/relative/path' -EnableException 3>$null } | Should -Throw
    }
}
