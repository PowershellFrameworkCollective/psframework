Describe "ConvertFrom-PSFArray Unit Tests" -Tag "UnitTests" {
    $object = [PSCustomObject]@{
        Foo  = 42
        Bar  = 18
        Tara = 21
    }

    $return = ConvertFrom-PSFArray -InputObject $object
    
    It "Test 1 - Should return PSCustomObject type" -TestCases @{ Return = $return } {
        $return.GetType().FullName | Should -Be System.Management.Automation.PSCustomObject
    }

    $command = get-command ConvertFrom-PSFArray
    It "Test 2 - <$command> Should contain ValueFromPipeline set to True" -TestCases @{ Command = $command } {
        $isTrue = $command.Definition | Select-String '[Parameter(ValueFromPipeline = $true)]' -quiet
        $isTrue | Should -Be $true
    }
}