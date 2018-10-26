Describe "Remove-PSFNull Unit Tests" -Tag "CI", "Pipeline", "Unit" {
	# Catch any signature changes to force revisiting the command
	It "Should have the designed for parameters & sets" {
		(Get-Command Remove-PSFNull).ParameterSets.Name | Should -Be '__AllParameterSets'
		foreach ($key in (Get-Command Remove-PSFNull).Parameters.Keys)
		{
			$key | Should -BeIn 'InputObject', 'AllowEmptyStrings', 'AllowEmptyCollections', 'Enumerate', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'
		}
	}
	
	It "Should allow only non-null values through" {
		1, 2, 3, $null, 4 | Remove-PSFNull | Should -Be 1, 2, 3, 4
		1, 2, 3, "", 4 | Remove-PSFNull | Should -Be 1, 2, 3, 4
		1, 2, 3, @(), 4 | Remove-PSFNull | Should -Be 1, 2, 3, 4
	}
	
	It "Should properly implement exceptions" {
		1, $null, 2, "", 3, @(), 4 | Remove-PSFNull | Should -Be 1, 2, 3, 4
		1, $null, 2, "", 3, @(), 4 | Remove-PSFNull -AllowEmptyStrings | Should -Be 1, 2, "", 3, 4
		1, $null, 2, "", 3, @(), 4 | Remove-PSFNull -AllowEmptyCollections | Should -Be 1, 2, 3, @(), 4
		1, $null, 2, "", 3, @(), 4 | Remove-PSFNull -AllowEmptyStrings -AllowEmptyCollections | Should -Be 1, 2, "", 3, @(), 4
	}
	
	It "Should not enumerate objects unless asked to" {
		( ,@(1, 2, 3) | Remove-PSFNull | Measure-Object).Count | Should -Be 1
		( ,@(1, 2, 3) | Remove-PSFNull -Enumerate | Measure-Object).Count | Should -Be 3
	}
}