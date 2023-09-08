Describe "Select-PSFObject Unit Tests" -Tag "UnitTests" {
	BeforeAll {
		$object = [PSCustomObject]@{
			Foo  = 42
			Bar  = 18
			Tara = 21
		}
		
		$object2 = [PSCustomObject]@{
			Foo = 42000
			Bar = 23
		}
		
		$list = @()
		$list += $object
		$list += [PSCustomObject]@{
			Foo  = 23
			Bar  = 88
			Tara = 28
		}
	}
	
	Describe "Basic DSL functionalities" {
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
	}
	
	Describe "Selects from other variables" {
		It "picks values from other variables" {
			($object2 | Select-PSFObject -Property 'Tara from object').Tara | Should -Be 21
		}
		
		It "picks values from the properties of the right object in a list" {
			($object2 | Select-PSFObject -Property 'Tara from List where Foo = Bar').Tara | Should -Be 28
		}
	}
	
	Describe "Display Settings are applied" {
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
	}
	
	Describe "Verifying input object integrity" {
		It "adds properties without harming the original object when used with -KeepInputObject" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject "Length as Size size KB:1:1" -KeepInputObject
			$modItem.GetType().FullName | Should -Be 'System.IO.FileInfo'
			$modItem.Size | Should -BeLike '* KB'
		}
	}
	
	Describe "Alias functionality applies" {
		It "adds aliases when using the -Alias parameter and specifying a string" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -Alias "Name as AliasName"
			$modItem.AliasName | Should -Be $modItem.Name
			$property = $modItem.PSObject.Properties["AliasName"]
			$property.MemberType | Should -Be 'AliasProperty'
			$property.Name | Should -Be 'AliasName'
			$property.Value | Should -Be $modItem.Name
			$property.ReferencedMemberName | Should -Be 'Name'
		}
		
		It "adds multiple aliases when using a hashtable on the -Alias parameter" {
			$item = [PSCustomObject]@{ Name = 'Foo.txt'; Length = 42; Extension = '.txt' }
			$modItem = $item | Select-PSFObject -KeepInputObject -Alias @{
				AliasName = "Name"
				Size	  = "Length"
				Ex	      = "Extension"
			}
			($modItem.PSObject.Properties | Group-Object MemberType | Where-Object Name -EQ "AliasProperty").Count | Should -Be 3
			($modItem.PSObject.Properties | Group-Object MemberType | Where-Object Name -EQ "AliasProperty").Group.Name | Should -BeIn AliasName, Size, Ex
		}
	}
	
	Describe "Script properties work in all supported notations" {
		It "adds a script property using the simple string notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptProperty 'Size := $this.Length * 2'
			$modItem.Size | Should -Be ($modItem.Length * 2)
			{ $modItem.Size = 23 } | Should -Throw
		}
		
		It "adds a script property using a less simple string notation that supports settable properties" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject Name, Length -ScriptProperty 'Size := $this.Length * 2 =: $this.Length = $args[0] / 2'
			$modItem.Length = 42
			$modItem.Size | Should -Be 84
			{ $modItem.Size = 22 } | Should -Not -Throw
			$modItem.Length | Should -Be 11
			$modItem.Size | Should -Be 22
		}
		
		It "adds a complex script property using a scriptblock" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject Name, Length -ScriptProperty { Size := $this.Length * 2 =: $this.Length = $args[0] / 2 }
			$modItem.Length = 42
			$modItem.Size | Should -Be 84
			{ $modItem.Size = 22 } | Should -Not -Throw
			$modItem.Length | Should -Be 11
			$modItem.Size | Should -Be 22
		}
		
		It "adds a script property using the simple hashtable notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject Name, Length -ScriptProperty @{ Size = { $this.Length * 2 } }
			$modItem.Size | Should -Be ($modItem.Length * 2)
			{ $modItem.Size = 23 } | Should -Throw
		}
		
		It "adds a script property using the complex hashtable notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject Name, Length -ScriptProperty @{
				Size = @{
					get = { $this.Length * 2 }
					set = { $this.Length = $args[0] / 2 }
				}
			}
			$modItem.Length = 42
			$modItem.Size | Should -Be 84
			{ $modItem.Size = 22 } | Should -Not -Throw
			$modItem.Length | Should -Be 11
			$modItem.Size | Should -Be 22
		}
		
		It "adds multiple script properties using the complex hashtable notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject Name, Length -ScriptProperty @{
				Size = @{
					get = { $this.Length * 2 }
					set = { $this.Length = $args[0] / 2 }
				}
				ExtraSize = @{
					get = { $this.Length * 3 }
				}
			}
			$modItem.Length = 42
			$modItem.Size | Should -Be 84
			$modItem.ExtraSize | Should -Be 126
			{ $modItem.Size = 22 } | Should -Not -Throw
			$modItem.Length | Should -Be 11
			$modItem.Size | Should -Be 22
			{ $modItem.ExtraSize = 22 } | Should -Throw
		}
		
		It "adds multiple script properties using the mixed complexity hashtable notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject Name, Length -ScriptProperty @{
				Size = @{
					get = { $this.Length * 2 }
					set = { $this.Length = $args[0] / 2 }
				}
				ExtraSize = { $this.Length * 3 }
			}
			$modItem.Length = 42
			$modItem.Size | Should -Be 84
			$modItem.ExtraSize | Should -Be 126
			{ $modItem.Size = 22 } | Should -Not -Throw
			$modItem.Length | Should -Be 11
			$modItem.Size | Should -Be 22
			{ $modItem.ExtraSize = 22 } | Should -Throw
		}
	}
	
	Describe "Script methods work in all supported notations" {
		It "adds a script method using the simple string notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptMethod 'GetSize => $this.Length * 2'
			$modItem.GetSize() | Should -Be ($modItem.Length * 2)
		}
		
		It "adds a script method using the scriptblock notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptMethod { GetSize => $this.Length * 2 }
			$modItem.GetSize() | Should -Be ($modItem.Length * 2)
		}
		
		It "adds a script method using the hashtable notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptMethod @{ GetSize = { $this.Length * 2 } }
			$modItem.GetSize() | Should -Be ($modItem.Length * 2)
		}
		
		It "adds multiple script methods using the hashtable notation" {
			$item = Get-Item "$PSScriptRoot\Select-PSFObject.Tests.ps1"
			$modItem = $item | Select-PSFObject -KeepInputObject -ScriptMethod @{
				GetSize	     = { $this.Length * 2 }
				GetExtraSize = { $this.Length * 3 }
			}
			$modItem.GetSize() | Should -Be ($modItem.Length * 2)
			$modItem.GetExtraSize() | Should -Be ($modItem.Length * 3)
		}
	}
}