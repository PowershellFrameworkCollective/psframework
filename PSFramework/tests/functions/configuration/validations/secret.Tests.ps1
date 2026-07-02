Describe "secret config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.secret'
        $seedCredential = [System.Management.Automation.PSCredential]::new('seed', (ConvertTo-SecureString 'seed' -AsPlainText -Force))
        Set-PSFConfig -FullName $script:fullName -Value $seedCredential -Validation 'secret' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        $validCredential = [System.Management.Automation.PSCredential]::new('valid', (ConvertTo-SecureString 'pw1' -AsPlainText -Force))
        { Set-PSFConfig -FullName $script:fullName -Value $validCredential -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).UserName | Should -Be 'valid'
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value 'plain-text-secret' -EnableException 3>$null } | Should -Not -Throw
        $value = Get-PSFConfigValue -FullName $script:fullName
        $value.GetType().FullName | Should -Be 'System.Management.Automation.PSCredential'
        $value.UserName | Should -Be '<none>'
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value ([byte[]](1,2,3)) -EnableException 3>$null } | Should -Throw
    }
}
