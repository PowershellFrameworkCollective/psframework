Describe "Import-PSFPowerShellDataFile Unit Tests" -Tag "UnitTests" {
	BeforeAll {
		$psd1Result = Import-PSFPowerShellDataFile -Path "$($global:testroot)\testdata\utility\ImportPsd1.psd1"
		$psd1ResultUnsafe = Import-PSFPowerShellDataFile -Path "$($global:testroot)\testdata\utility\ImportPsd1.psd1" -Unsafe
		$jsonResult = Import-PSFPowerShellDataFile -Path "$($global:testroot)\testdata\utility\ImportJson.json"
	}

	Describe "Imports PSD1 files correctly" {
		It "Should only contain one result" {
			($psd1Result | Measure-Object).Count | Should -Be 1
		}
		It "Should contain three keys" {
			$psd1Result.Keys.Count | Should -Be 3
		}
		It "Should have the expected values" {
			$psd1Result.Name | Should -Be "Fred"
			$psd1Result.Age | Should -Be 66
		}
	}

	Describe "Imports PSD1 files (unsafe) correctly" {
		It "Should only contain two results" {
			($psd1ResultUnsafe | Measure-Object).Count | Should -Be 2
		}
		It "Should contain three keys & 2 Keys" {
			$psd1ResultUnsafe[0].Keys.Count | Should -Be 3
			$psd1ResultUnsafe[1].Keys.Count | Should -Be 2
		}
		It "Should have the expected values" {
			$psd1ResultUnsafe[0].Name | Should -Be "Fred"
			$psd1ResultUnsafe[0].Age | Should -Be 66
			$psd1ResultUnsafe[1].Name | Should -Be "Max"
			$psd1ResultUnsafe[1].Nachname | Should -Be "Mustermann"
		}
	}

	Describe "Imports Json files correctly" {
		It "Should enumerate correctly" {
			(Import-PSFPowerShellDataFile -Path "$($global:testroot)\testdata\utility\ImportJson.json" | Measure-Object).Count | Should -Be 2
		}
		It "Should have two results" {
			($jsonResult | Measure-Object).Count | Should -Be 2
		}
		It "Should contain three keys & 2 Keys" {
			$jsonResult[0].Keys.Count | Should -Be 3
			$jsonResult[1].Keys.Count | Should -Be 2
		}
		It "Should have the expected values" {
			$jsonResult[0].Name | Should -Be "Fred"
			$jsonResult[0].Age | Should -Be 66
			$jsonResult[1].Name | Should -Be "Max"
			$jsonResult[1].Nachname | Should -Be "Mustermann"
		}
	}
}