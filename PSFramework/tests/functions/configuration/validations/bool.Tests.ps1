Describe "bool config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.bool'
        Set-PSFConfig -FullName $script:fullName -Value $false -Validation 'bool' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value $true -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $true
    }

    It "accepts values that require conversion" {
        $switchValue = [System.Management.Automation.SwitchParameter]::new($true)
        { Set-PSFConfig -FullName $script:fullName -Value $switchValue -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).GetType().FullName | Should -Be 'System.Boolean'
        Get-PSFConfigValue -FullName $script:fullName | Should -Be $true
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'true' -EnableException 3>$null } | Should -Throw
    }
}
