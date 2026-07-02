Describe "sizestyle config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.sizestyle'
        $script:enumNames = [enum]::GetNames([PSFramework.Utility.SizeStyle])
        Set-PSFConfig -FullName $script:fullName -Value $script:enumNames[0] -Validation 'sizestyle' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        $value = [PSFramework.Utility.SizeStyle]$script:enumNames[0]
        { Set-PSFConfig -FullName $script:fullName -Value $value -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $value
    }

    It "accepts values that require conversion" {
        $convertedName = if ($script:enumNames.Count -gt 1) { $script:enumNames[1] } else { $script:enumNames[0] }
        $expected = [PSFramework.Utility.SizeStyle]$convertedName
        { Set-PSFConfig -FullName $script:fullName -Value $convertedName -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $expected
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'not-a-size-style' -EnableException 3>$null } | Should -Throw
    }
}
