Describe "Select-PSFObject Unit Tests" -Tag "UnitTests" {
	$global:object = [PSCustomObject]@{
		Foo  = 42
		Bar  = 18
		Tara = 21
	}
	
	$global:object2 = [PSCustomObject]@{
		Foo = 42000
		Bar = 23
	}
	
	$global:list = @()
	$global:list += $object
	$global:list += [PSCustomObject]@{
		Foo  = 23
		Bar  = 88
		Tara = 28
	}
	
	It "renames Bar to Bar2" {
		($object | Select-PSFObject -Property 'Foo', 'Bar as Bar2').PSObject.Properties.Name | Should -Be 'Foo', 'Bar2'
	}
	
	It "changes Bar to string" {
		($object | Select-PSFObject -Property 'Bar to string').Bar.GetType().FullName | Should -Be 'System.String'
	}
	
	It "converts numbers to sizes" {
		($object2 | Select-PSFObject -Property 'Foo size KB:1').Foo | Should -Be 41
		($object2 | Select-PSFObject -Property 'Foo size KB:1:1').Foo | Should -Be "41 KB"
	}
	
	It "picks values from other variables" {
		($object2 | Select-PSFObject -Property 'Tara from object').Tara | Should -Be 21
	}
	
	It "picks values from the properties of the right object in a list" {
		($object2 | Select-PSFObject -Property 'Tara from List where Foo = Bar').Tara | Should -Be 28
	}
	
	It "sets the correct properties to show in whitelist mode" {
		$obj = [PSCustomObject]@{ Foo = "Bar"; Bar = 42; Right = "Left" }
		$null = $obj | Select-PSFObject -ShowProperty Foo, Bar
		$obj.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames | Should -Be 'Foo', 'Bar'
	}
	
	It "sets the correct properties to show in blacklist mode" {
		$obj = [PSCustomObject]@{ Foo = "Bar"; Bar = 42; Right = "Left" }
		$null = $obj | Select-PSFObject -ShowExcludeProperty Foo
		$obj.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames | Should -Be 'Bar', 'Right'
	}
	
	It "sets the correct typename" {
		$obj = [PSCustomObject]@{ Foo = "Bar"; Bar = 42; Right = "Left" }
		$null = $obj | Select-PSFObject -TypeName 'Foo.Bar'
		$obj.PSObject.TypeNames[0] | Should -Be 'Foo.Bar'
	}
	
	It "adds properties without harming the original object when used with -KeepInputObject" {
		$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
		$modItem = $item | Select-PSFObject "Length as Size size KB:1:1" -KeepInputObject
		$modItem.GetType().FullName | Should -Be 'System.IO.FileInfo'
		$modItem.Size | Should -BeLike '* KB'
	}
}