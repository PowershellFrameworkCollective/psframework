Describe "guidarray config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.guidarray'
        Set-PSFConfig -FullName $script:fullName -Value @([guid]::Empty) -Validation 'guidarray' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        $g1 = [guid]::NewGuid()
        $g2 = [guid]::NewGuid()
        { Set-PSFConfig -FullName $script:fullName -Value @($g1, $g2) -EnableException 3>$null } | Should -Not -Throw
        $value = Get-PSFConfigValue -FullName $script:fullName
        $value[0] | Should -Be $g1
        $value[1] | Should -Be $g2
    }

    It "accepts values that require conversion" {
        $g1 = [guid]::NewGuid()
        $g2 = [guid]::NewGuid()
        { Set-PSFConfig -FullName $script:fullName -Value @($g1.Guid, $g2.Guid) -EnableException 3>$null } | Should -Not -Throw
        $value = Get-PSFConfigValue -FullName $script:fullName
        $value[0].GetType().FullName | Should -Be 'System.Guid'
        $value[1].GetType().FullName | Should -Be 'System.Guid'
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value @('still-not-a-guid') -EnableException 3>$null } | Should -Throw
    }
}
