Describe "Select-PSFPropertyValue Unit Tests" -Tag "Unit" {
	BeforeAll {
		# Place here all things needed to prepare for the tests
		$object = [pscustomobject]@{
			Length   = 42
			Name	 = "Foo"
			FullName = "Foo.Bar.Com"
			Empty    = ""
			Null	 = $null
			Zero	 = 0
		}
	}
	AfterAll {
		# Here is where all the cleanup tasks go
	}
	
	#region Signature Test
	Describe "Ensuring unchanged command signature" {
		It "should have the expected parameter sets" {
			(Get-Command Select-PSFPropertyValue).ParameterSets.Name | Should -Be 'Default', 'Fallback', 'Select', 'Join', 'Format'
		}
		
		It 'Should have the expected parameter Property' {
			$parameter = (Get-Command Select-PSFPropertyValue).Parameters['Property']
			$parameter.Name | Should -Be 'Property'
			$parameter.ParameterType.ToString() | Should -Be System.String[]
			$parameter.IsDynamic | Should -Be $False
			$parameter.ParameterSets.Keys | Should -Be '__AllParameterSets'
			$parameter.ParameterSets.Keys | Should -Contain '__AllParameterSets'
			$parameter.ParameterSets['__AllParameterSets'].IsMandatory | Should -Be $True
			$parameter.ParameterSets['__AllParameterSets'].Position | Should -Be 0
			$parameter.ParameterSets['__AllParameterSets'].ValueFromPipeline | Should -Be $False
			$parameter.ParameterSets['__AllParameterSets'].ValueFromPipelineByPropertyName | Should -Be $False
			$parameter.ParameterSets['__AllParameterSets'].ValueFromRemainingArguments | Should -Be $False
		}
		It 'Should have the expected parameter Fallback' {
			$parameter = (Get-Command Select-PSFPropertyValue).Parameters['Fallback']
			$parameter.Name | Should -Be 'Fallback'
			$parameter.ParameterType.ToString() | Should -Be System.Management.Automation.SwitchParameter
			$parameter.IsDynamic | Should -Be $False
			$parameter.ParameterSets.Keys | Should -Be 'Fallback'
			$parameter.ParameterSets.Keys | Should -Contain 'Fallback'
			$parameter.ParameterSets['Fallback'].IsMandatory | Should -Be $False
			$parameter.ParameterSets['Fallback'].Position | Should -Be -2147483648
			$parameter.ParameterSets['Fallback'].ValueFromPipeline | Should -Be $False
			$parameter.ParameterSets['Fallback'].ValueFromPipelineByPropertyName | Should -Be $False
			$parameter.ParameterSets['Fallback'].ValueFromRemainingArguments | Should -Be $False
		}
		It 'Should have the expected parameter Select' {
			$parameter = (Get-Command Select-PSFPropertyValue).Parameters['Select']
			$parameter.Name | Should -Be 'Select'
			$parameter.ParameterType.ToString() | Should -Be System.String
			$parameter.IsDynamic | Should -Be $False
			$parameter.ParameterSets.Keys | Should -Be 'Select'
			$parameter.ParameterSets.Keys | Should -Contain 'Select'
			$parameter.ParameterSets['Select'].IsMandatory | Should -Be $False
			$parameter.ParameterSets['Select'].Position | Should -Be -2147483648
			$parameter.ParameterSets['Select'].ValueFromPipeline | Should -Be $False
			$parameter.ParameterSets['Select'].ValueFromPipelineByPropertyName | Should -Be $False
			$parameter.ParameterSets['Select'].ValueFromRemainingArguments | Should -Be $False
		}
		It 'Should have the expected parameter JoinBy' {
			$parameter = (Get-Command Select-PSFPropertyValue).Parameters['JoinBy']
			$parameter.Name | Should -Be 'JoinBy'
			$parameter.ParameterType.ToString() | Should -Be System.String
			$parameter.IsDynamic | Should -Be $False
			$parameter.ParameterSets.Keys | Should -Be 'Join'
			$parameter.ParameterSets.Keys | Should -Contain 'Join'
			$parameter.ParameterSets['Join'].IsMandatory | Should -Be $False
			$parameter.ParameterSets['Join'].Position | Should -Be -2147483648
			$parameter.ParameterSets['Join'].ValueFromPipeline | Should -Be $False
			$parameter.ParameterSets['Join'].ValueFromPipelineByPropertyName | Should -Be $False
			$parameter.ParameterSets['Join'].ValueFromRemainingArguments | Should -Be $False
		}
		It 'Should have the expected parameter FormatWith' {
			$parameter = (Get-Command Select-PSFPropertyValue).Parameters['FormatWith']
			$parameter.Name | Should -Be 'FormatWith'
			$parameter.ParameterType.ToString() | Should -Be System.String
			$parameter.IsDynamic | Should -Be $False
			$parameter.ParameterSets.Keys | Should -Be 'Format'
			$parameter.ParameterSets.Keys | Should -Contain 'Format'
			$parameter.ParameterSets['Format'].IsMandatory | Should -Be $False
			$parameter.ParameterSets['Format'].Position | Should -Be -2147483648
			$parameter.ParameterSets['Format'].ValueFromPipeline | Should -Be $False
			$parameter.ParameterSets['Format'].ValueFromPipelineByPropertyName | Should -Be $False
			$parameter.ParameterSets['Format'].ValueFromRemainingArguments | Should -Be $False
		}
		It 'Should have the expected parameter InputObject' {
			$parameter = (Get-Command Select-PSFPropertyValue).Parameters['InputObject']
			$parameter.Name | Should -Be 'InputObject'
			$parameter.ParameterType.ToString() | Should -Be System.Object
			$parameter.IsDynamic | Should -Be $False
			$parameter.ParameterSets.Keys | Should -Be '__AllParameterSets'
			$parameter.ParameterSets.Keys | Should -Contain '__AllParameterSets'
			$parameter.ParameterSets['__AllParameterSets'].IsMandatory | Should -Be $False
			$parameter.ParameterSets['__AllParameterSets'].Position | Should -Be -2147483648
			$parameter.ParameterSets['__AllParameterSets'].ValueFromPipeline | Should -Be $True
			$parameter.ParameterSets['__AllParameterSets'].ValueFromPipelineByPropertyName | Should -Be $False
			$parameter.ParameterSets['__AllParameterSets'].ValueFromRemainingArguments | Should -Be $False
		}
	}
	#endregion Signature Test
	
	Describe "Testing parameterset Default" {
		It "Should select a single property correctly" {
			$object | Select-PSFPropertyValue -Property 'Length' | Should -Be 42
		}
		
		It "Should select multiple properties correctly" {
			$object | Select-PSFPropertyValue -Property 'Length', 'Name' | Should -Be 42, 'Foo'
		}
	}
	Describe "Testing parameterset Fallback" {
		It "Testing Fallback: All exist, nothing special" {
			$object | Select-PSFPropertyValue -Property 'Length', 'Name' -Fallback | Should -Be 42
		}
		It "Testing Fallback: Null and filled" {
			$object | Select-PSFPropertyValue -Property 'Null', 'Name' -Fallback | Should -Be 'Foo'
		}
		It "Testing Fallback: Zero and filled" {
			$object | Select-PSFPropertyValue -Property 'Zero', 'Name' -Fallback | Should -Be 0
		}
		It "Testing Fallback: Empty string and filled" {
			$object | Select-PSFPropertyValue -Property 'Empty', 'Name' -Fallback | Should -Be 'Foo'
		}
	}
	Describe "Testing parameterset Select" {
		It "Should select the largest property value" {
			$object | Select-PSFPropertyValue -Property Name, FullName, Length -Select Largest | Should -Be 'Foo.Bar.Com'
		}
		It "Should select the lowest property value" {
			$object | Select-PSFPropertyValue -Property Name, FullName, Length -Select  Lowest| Should -Be 42
		}
	}
	Describe "Testing parameterset Join" {
		It "Should correctly join selected properties" {
			$object | Select-PSFPropertyValue 'Name', 'Length' -JoinBy "|" | Should -Be 'Foo|42'
		}
	}
	Describe "Testing parameterset Format" {
		It "Should insert values into the specified format" {
			$object | Select-PSFPropertyValue 'Name', 'Length', 'FullName' -FormatWith '{0} | {2} | {1:D3}' | Should -Be 'Foo | Foo.Bar.Com | 042'
		}
	}
}