Describe "New-PSFTempFile Unit Tests" -Tag "UnitTests" {
	AfterEach {
		Get-PSFTempItem -ModuleName PSFTests | Remove-PSFTempItem
	}

	It "Should create and track the file specified by -FileName" {
		$fileName = "PSF_Test_$(New-Guid).csv"
		$expected = Join-Path -Path (Get-PSFPath -Name Temp) -ChildPath $fileName

		$result = New-PSFTempFile -ModuleName PSFTests -Name FileNameTest -FileName $fileName

		@($result).Count | Should -Be 1
		$result | Should -Be $expected
		Test-Path -LiteralPath $expected | Should -BeTrue
		(Get-PSFTempItem -ModuleName PSFTests -Name FileNameTest).Path | Should -Be $expected
	}

	It "Should create and track a generated file without -FileName" {
		$result = New-PSFTempFile -ModuleName PSFTests -Name GeneratedTest -Extension csv

		@($result).Count | Should -Be 1
		$result | Should -BeLike '*\PSF_Temp_*.csv'
		Test-Path -LiteralPath $result | Should -BeTrue
		(Get-PSFTempItem -ModuleName PSFTests -Name GeneratedTest).Path | Should -Be $result
	}
}