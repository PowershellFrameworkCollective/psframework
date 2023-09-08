Describe "Parameter Class: PsfFile Unit Tests" {
	BeforeAll {
		function Get-File {
			[CmdletBinding()]
			param (
				[PsfFile]
				$Path
			)
			foreach ($entry in $Path) {
				$entry
			}
		}

		$folder = New-PSFTempDirectory -ModuleName PSFTest -Name TempFolder
		$folder = (Resolve-Path -LiteralPath $folder).ProviderPath
		"Test" | Set-Content -Path "$folder\test1.txt"
		"Test" | Set-Content -Path "$folder\test2.txt"
		"Test" | Set-Content -Path "$folder\test3.txt"
		$null = New-Item -Path $folder -Name Test -ItemType Directory
		$file1 = Get-Item -Path "$folder\test1.txt"
		$file2 = Get-Item -Path "$folder\test2.txt"

		[PsfFile]::SetTypePropertyMapping('Test.Type', 'Path')

		$testObject = [PSCustomObject]@{
			PSTypeName = 'Test.Type'
			Fake       = "$folder\test4.txt"
			Path       = "$folder\test3.txt"
		}
	}
	AfterAll {
		Remove-PSFTempItem -ModuleName PSFTest -Name TempFolder
	}

	It "Should process an explicit path without error" {
		Get-File -Path "$folder\test1.txt" | Should -Be "$folder\test1.txt"
	}
	It "Should process wildcard paths, disregarding folders" {
		Get-File -Path "$folder\tes*" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
	}
	It "Should error on folders" {
		{ Get-File -Path "$folder\test" } | Should -Throw
	}
	It "Should error on wildcard paths that do not resolve to at least one file" {
		{ Get-File -Path "$folder\test\*" } | Should -Throw
	}
	It "Should process multiple paths" {
		Get-File -Path "$folder\test[12].txt", "$folder\test3.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
	}
	It "Should accept a FileInfo object" {
		Get-File -Path $file1 | Should -Be $file1.FullName
	}
	It "Should accept multiple FileInfo objects" {
		Get-File -Path $file1, $file2 | Should -Be "$folder\test1.txt", "$folder\test2.txt"
	}
	It "Should deduplicate multiple same paths" {
		Get-File -Path $file1, $file1 | Should -Be "$folder\test1.txt"
	}
	It "Should accept a mix of different types of objects" {
		Get-File -Path $file1, $file2, "$folder\test3.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
	}
	It "Should not accept a DirectoryInfo object" {
		{ Get-File -Path (Get-Item -Path $folder) } | Should -Throw
	}
	It "Should accept a custom object that has registered a conversion" {
		Get-File -Path $testObject | Should -Be "$folder\test3.txt"
	}
}