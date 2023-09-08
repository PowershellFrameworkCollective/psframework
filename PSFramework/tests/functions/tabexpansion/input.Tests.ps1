Describe 'Completion tests: input' {
	BeforeAll {
		function Complete
		{
			[CmdletBinding()]
			param (
				[string]
				$Expression
			)
			process
			{
				[System.Management.Automation.CommandCompletion]::CompleteInput(
					$Expression,
					$Expression.Length,
					$null
				).CompletionMatches
			}
		}
	}
	It 'can complete input from Get-ChildItem' {
		(Complete -Expression 'Get-ChildItem | Select-PSFObject ').CompletionText | Should -Match '^Attributes$|^BaseName$|^CreationTime$|^CreationTimeUtc$|^Directory$|^DirectoryName$|^Exists$|^Extension$|^FullName$|^IsReadOnly$|^LastAccessTime$|^LastAccessTimeUtc$|^LastWriteTime$|^LastWriteTimeUtc$|^Length$|^Name$|^Parent$|^PSChildName$|^PSDrive$|^PSIsContainer$|^PSParentPath$|^PSPath$|^PSProvider$|^Root$|^VersionInfo$|^LinkTarget$|^UnixFileMode$'
		(Complete -Expression 'Get-ChildItem | Select-PSFObject ').Count | Should -Be 25
	}
	
	<#
	It 'can complete type name' {
		Complete 'Find-Type -Name Toke' | Should -All { $_.CompletionText.StartsWith('Token') }
	}
	
	It 'can complete type full names' {
		Complete 'Find-Member -ReturnType Ast' | Should -All { $_.CompletionText -match '\.Ast' }
	}
	
	It 'can complete namespace names' {
		Complete 'Find-Namespace Autom' | Should -HaveProperty CompletionText -WithValue Automation
	}
	
	It 'can complete namespaces' {
		Complete 'Find-Namespace -FullName Autom' |
		Should -HaveProperty CompletionText -WithValue System.Management.Automation
	}
	
	It 'can complete assembly names' {
		Complete 'Get-Assembly System.Management.Autom' |
		Should -HaveProperty CompletionText -WithValue System.Management.Automation
	}
	#>
}