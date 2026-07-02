Describe "languagecode config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.languagecode'
        Set-PSFConfig -FullName $script:fullName -Value 'en-US' -Validation 'languagecode' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value 'de-DE' -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 'de-DE'
    }

    It "accepts values that require conversion" {
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo('fr-FR')
        { Set-PSFConfig -FullName $script:fullName -Value $culture -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be 'fr-FR'
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'zz-INVALID' -EnableException 3>$null } | Should -Throw
    }
}
