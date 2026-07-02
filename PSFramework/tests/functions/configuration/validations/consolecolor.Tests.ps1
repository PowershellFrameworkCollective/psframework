Describe "consolecolor config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        $script:fullName = 'PSFTests.Validation.consolecolor'
        Set-PSFConfig -FullName $script:fullName -Value ([System.ConsoleColor]::Black) -Validation 'consolecolor' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value ([System.ConsoleColor]::Red) -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be ([System.ConsoleColor]::Red)
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value 'Blue' -EnableException 3>$null } | Should -Not -Throw
        Get-PSFConfigValue -FullName $script:fullName | Should -Be ([System.ConsoleColor]::Blue)
    }

    It "rejects invalid values" {
        { Set-PSFConfig -FullName $script:fullName -Value 'NoColor' -EnableException 3>$null } | Should -Throw
    }
}
