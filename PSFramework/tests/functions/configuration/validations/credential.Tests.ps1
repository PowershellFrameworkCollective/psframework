Describe "credential config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.credential'
        $script:seedCredential = [System.Management.Automation.PSCredential]::new('seed', (ConvertTo-SecureString 'seed' -AsPlainText -Force))
        Set-PSFConfig -FullName $script:fullName -Value $script:seedCredential -Validation 'credential' -Initialize -AllowDelete -EnableException 3>$null
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
        $securePassword = ConvertTo-SecureString 'pw2' -AsPlainText -Force
        $convertedCredential = [System.Management.Automation.PSCredential]::new('converted', $securePassword)
        { Set-PSFConfig -FullName $script:fullName -Value $convertedCredential -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).UserName | Should -Be 'converted'
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'not-a-credential' -EnableException 3>$null } | Should -Throw
    }
}
