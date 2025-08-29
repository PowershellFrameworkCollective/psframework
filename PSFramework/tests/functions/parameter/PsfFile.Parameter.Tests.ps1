Describe "Parameter Class: Path Parameter Class Unit Tests" {
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

		function Get-File2 {
			[CmdletBinding()]
			param (
				[PsfFile]
				$File,

				[PsfFileLax]
				$FileLax,

				[PsfFileSingle]
				$FileSingle,

				[PsfDirectory]
				$Directory,

				[PsfDirectoryLax]
				$DirectoryLax,

				[PsfDirectorySingle]
				$DirectorySingle,

				[PsfPath]
				$Path,

				[PsfPathLax]
				$PathLax,

				[PsfPathSingle]
				$PathSingle,

				[PsfLiteralPath]
				$LiteralPath,

				[PsfLiteralPathLax]
				$LiteralPathLax,

				[PsfLiteralPathSingle]
				$LiteralPathSingle,

				[PsfLiteralFileSingle]
				$LiteralFileSingle,

				[PsfLiteralDirectorySingle]
				$LiteralDirectorySingle,

				[PsfNewFile]
				$NewFile,

				[PsfNewFileSingle]
				$NewFileSingle
			)
			$PSBoundParameters.Values | Write-Output
		}

		$folder = New-PSFTempDirectory -ModuleName PSFTest -Name TempFolder
		$folder = (Get-Item -LiteralPath (Resolve-Path -LiteralPath $folder).ProviderPath).FullName
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

	#region Path
	Describe "Testing the Path-Classes that interpret wildcards" {
		#region PsfFile
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
		#endregion PsfFile

		It "Should process [PsfFileLax] correctly" {
			Get-File2 -FileLax $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -FileLax $file1, $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -FileLax $file1, $file2, "$folder\test3.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
			Get-File2 -FileLax $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
			Get-File2 -FileLax $folder | Should -BeNullOrEmpty
			Get-File2 -FileLax "$folder\test4.txt" | Should -BeNullOrEmpty
			Get-File2 -FileLax "$folder\*.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
		}

		It "Should process [PsfFileSingle] correctly" {
			Get-File2 -FileSingle $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -FileSingle $file2 | Should -Be "$folder\test2.txt"
			{ Get-File2 -FileSingle $file1, $file2 } | Should -Throw
			{ Get-File2 -FileSingle $folder } | Should -Throw
			{ Get-File2 -FileSingle "$folder\*.txt" } | Should -Throw
			{ Get-File2 -FileSingle "$folder\test4.txt" } | Should -Throw
		}

		It "Should process [PsfDirectory] correctly" {
			Get-File2 -Directory $folder | Should -Be $folder
			Get-File2 -Directory (Get-Item -LiteralPath $folder) | Should -Be $folder
			Get-File2 -Directory (Get-Item -LiteralPath $folder), (Get-Item -Path .) | Should -Be $folder, (Get-Item -Path .).FullName
			{ Get-File2 -Directory $file1 } | Should -Throw
			{ Get-File2 -Directory "$($folder)2" } | Should -Throw
		}

		It "Should process [PsfDirectoryLax] correctly" {
			Get-File2 -DirectoryLax $folder | Should -Be $folder
			Get-File2 -DirectoryLax (Get-Item -LiteralPath $folder) | Should -Be $folder
			Get-File2 -DirectoryLax (Get-Item -LiteralPath $folder), (Get-Item -Path .) | Should -Be $folder, (Get-Item -Path .).FullName
			{ Get-File2 -DirectoryLax $file1 } | Should -Not -Throw
			{ Get-File2 -DirectoryLax "$($folder)2" } | Should -Not -Throw
		}

		It "Should process [PsfDirectorySingle] correctly" {
			Get-File2 -DirectorySingle $folder | Should -Be $folder
			Get-File2 -DirectorySingle (Get-Item -LiteralPath $folder) | Should -Be $folder
			{ Get-File2 -DirectorySingle (Get-Item -LiteralPath $folder), (Get-Item -Path .) } | Should -Throw
			{ Get-File2 -DirectorySingle $file1 } | Should -Throw
			{ Get-File2 -DirectorySingle "$($folder)2" } | Should -Throw
		}

		It "Should process [PsfPath] correctly" {
			Get-File2 -Path $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -Path $file1, $folder | Should -Be "$folder\test1.txt", $folder
			Get-File2 -Path $file1, $folder, $folder | Should -Be "$folder\test1.txt", $folder
			Get-File2 -Path $file1, $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -Path $file1, $file2, "$folder\test3.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
			{ Get-File2 -Path $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" } | Should -Throw
			Get-File2 -Path $folder | Should -Be $folder
			{ Get-File2 -Path "$folder\test4.txt" } | Should -Throw
			Get-File2 -Path "$folder\*.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
		}

		It "Should process [PsfPathLax] correctly" {
			Get-File2 -PathLax $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -PathLax $file1, $folder | Should -Be "$folder\test1.txt", $folder
			Get-File2 -PathLax $file1, $folder, $folder | Should -Be "$folder\test1.txt", $folder
			Get-File2 -PathLax $file1, $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -PathLax $file1, $file2, "$folder\test3.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
			Get-File2 -PathLax $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
			Get-File2 -PathLax $folder | Should -Be $folder
			Get-File2 -PathLax "$folder\test4.txt" | Should -BeNullOrEmpty
			Get-File2 -PathLax "$folder\*.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
		}

		It "Should process [PsfPathSingle] correctly" {
			Get-File2 -PathSingle $file1 | Should -Be "$folder\test1.txt"
			{ Get-File2 -PathSingle $file1, $folder } | Should -Throw
			{ Get-File2 -PathSingle $file1, $folder, $folder } | Should -Throw
			{ Get-File2 -PathSingle $file1, $file1 } | Should -Throw
			{ Get-File2 -PathSingle $file1, $file2, "$folder\test3.txt" } | Should -Throw
			{ Get-File2 -PathSingle $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" } | Should -Throw
			Get-File2 -PathSingle $folder | Should -Be $folder
			{ Get-File2 -PathSingle "$folder\test4.txt" } | Should -Throw
			{ Get-File2 -PathSingle "$folder\*.txt" } | Should -Throw
			Get-File2 -PathSingle "$folder\*3.txt" | Should -Be "$folder\test3.txt"
		}
	}
	#endregion Path

	#region LiteralPath
	Describe "Testing the Path-Classes that take things literal" {
		It "Should process [PsfLiteralPath] correctly" {
			Get-File2 -LiteralPath $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -LiteralPath $folder | Should -Be $folder
			Get-File2 -LiteralPath (Get-Item -LiteralPath $folder) | Should -Be $folder
			Get-File2 -LiteralPath $file1, $file2 | Should -Be "$folder\test1.txt", "$folder\test2.txt"
			Get-File2 -LiteralPath $file1, $file2, "$folder\test3.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
			{ Get-File2 -LiteralPath $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" } | Should -Throw
			{ Get-File2 -LiteralPath "$folder\*.txt" } | Should -Throw
		}

		It "Should process [PsfLiteralPathLax] correctly" {
			Get-File2 -LiteralPathLax $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -LiteralPathLax $folder | Should -Be $folder
			Get-File2 -LiteralPathLax (Get-Item -LiteralPath $folder) | Should -Be $folder
			Get-File2 -LiteralPathLax $file1, $file2 | Should -Be "$folder\test1.txt", "$folder\test2.txt"
			Get-File2 -LiteralPathLax $file1, $file2, "$folder\test3.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
			Get-File2 -LiteralPathLax $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" | Should -Be "$folder\test1.txt", "$folder\test2.txt", "$folder\test3.txt"
			Get-File2 -LiteralPathLax "$folder\*.txt" | Should -BeNullOrEmpty
		}

		It "Should process [PsfLiteralPathSingle] correctly" {
			Get-File2 -LiteralPathSingle $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -LiteralPathSingle $folder | Should -Be $folder
			Get-File2 -LiteralPathSingle (Get-Item -LiteralPath $folder) | Should -Be $folder
			{ Get-File2 -LiteralPathSingle $file1, $file2 } | Should -Throw
			{ Get-File2 -LiteralPathSingle $file1, $file2, "$folder\test3.txt" } | Should -Throw
			{ Get-File2 -LiteralPathSingle $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" } | Should -Throw
			{ Get-File2 -LiteralPathSingle "$folder\*.txt" } | Should -Throw
		}

		It "Should process [PsfLiteralFileSingle] correctly" {
			Get-File2 -LiteralFileSingle $file1 | Should -Be "$folder\test1.txt"
			{ Get-File2 -LiteralFileSingle $folder } | Should -Throw
			{ Get-File2 -LiteralFileSingle (Get-Item -LiteralPath $folder) } | Should -Throw
			{ Get-File2 -LiteralFileSingle $file1, $file2 } | Should -Throw
			{ Get-File2 -LiteralFileSingle $file1, $file2, "$folder\test3.txt" } | Should -Throw
			{ Get-File2 -LiteralFileSingle $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" } | Should -Throw
			{ Get-File2 -LiteralFileSingle "$folder\*.txt" } | Should -Throw
		}

		It "Should process [PsfLiteralDirectorySingle] correctly" {
			{ Get-File2 -LiteralDirectorySingle $file1 } | Should -Throw
			Get-File2 -LiteralDirectorySingle $folder | Should -Be $folder
			Get-File2 -LiteralDirectorySingle (Get-Item -LiteralPath $folder) | Should -Be $folder
			{ Get-File2 -LiteralDirectorySingle $file1, $file2 } | Should -Throw
			{ Get-File2 -LiteralDirectorySingle $file1, $file2, "$folder\test3.txt" } | Should -Throw
			{ Get-File2 -LiteralDirectorySingle $file1, $file2, "$folder\test3.txt", "$folder\test4.txt" } | Should -Throw
			{ Get-File2 -LiteralDirectorySingle "$folder\*.txt" } | Should -Throw
		}
	}
	#endregion LiteralPath

	#region NewFile
	Describe "Testing the Path-Classes that accept paths to new files" {
		It "Should process [PsfNewFile] correctly" {
			Get-File2 -NewFile $file1 | Should -Be "$folder\test1.txt"
			Get-File2 -NewFile $file1, $file2 | Should -Be "$folder\test1.txt", "$folder\test2.txt"
			{ Get-File2 -NewFile $file1, $file2, $folder } | Should -Throw
			{ Get-File2 -NewFile $folder } | Should -Throw
			Get-File2 -NewFile "$folder\test5.txt" | Should -Be "$folder\test5.txt"
			Get-File2 -NewFile "$folder\test5.txt", "$folder\test6.txt" | Should -Be "$folder\test5.txt", "$folder\test6.txt"
			Get-File2 -NewFile $file1, "$folder\test5.txt", "$folder\test6.txt" | Should -Be "$folder\test1.txt", "$folder\test5.txt", "$folder\test6.txt"
			{ Get-File2 -NewFile "$folder abc\test1.txt" } | Should -Throw
			{ Get-File2 -NewFile "$folder abc\test1.txt", "$folder\test1.txt" } | Should -Throw
		}

		It "Should process [PsfNewFileSingle] correctly" {
			Get-File2 -NewFileSingle $file1 | Should -Be "$folder\test1.txt"
			{ Get-File2 -NewFileSingle $file1, $file2 } | Should -Throw
			{ Get-File2 -NewFileSingle $file1, $file2, $folder } | Should -Throw
			{ Get-File2 -NewFileSingle $folder } | Should -Throw
			Get-File2 -NewFileSingle "$folder\test5.txt" | Should -Be "$folder\test5.txt"
			{ Get-File2 -NewFileSingle "$folder\test5.txt", "$folder\test6.txt" } | Should -Throw
			{ Get-File2 -NewFileSingle $file1, "$folder\test5.txt", "$folder\test6.txt" } | Should -Throw
			{ Get-File2 -NewFileSingle "$folder abc\test1.txt" } | Should -Throw
			{ Get-File2 -NewFileSingle "$folder abc\test1.txt", "$folder\test1.txt" } | Should -Throw
		}
	}
	#endregion NewFile
}