Describe "stringarray config validation" -Tag "CI", "Config", "Unit" {
    BeforeAll {
        Add-Type -TypeDefinition @"
public class PSFStringArrayThrowingToString {
    public override string ToString() {
        throw new System.InvalidOperationException("No string representation");
    }
}
"@ -ErrorAction SilentlyContinue

        $script:fullName = 'PSFTests.Validation.stringarray'
        Set-PSFConfig -FullName $script:fullName -Value @('seed') -Validation 'stringarray' -Initialize -AllowDelete -EnableException 3>$null
    }

    AfterAll {
        Remove-PSFConfig -FullName $script:fullName -Confirm:$false 3>$null
    }

    It "accepts values that are already valid" {
        { Set-PSFConfig -FullName $script:fullName -Value @('one', 'two') -EnableException 3>$null } | Should -Not -Throw
        (Get-PSFConfigValue -FullName $script:fullName).Count | Should -Be 2
    }

    It "accepts values that require conversion" {
        { Set-PSFConfig -FullName $script:fullName -Value @(1, $true, [guid]::Empty) -EnableException 3>$null } | Should -Not -Throw
        $value = Get-PSFConfigValue -FullName $script:fullName
        $value[0] | Should -Be '1'
        $value[1] | Should -Be 'True'
    }

    It "rejects invalid values" {
        $badValue = [PSFStringArrayThrowingToString]::new()
        { Set-PSFConfig -FullName $script:fullName -Value @($badValue) -EnableException 3>$null } | Should -Throw
    }
}
