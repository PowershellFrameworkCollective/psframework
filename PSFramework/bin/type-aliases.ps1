# Define our type aliases
$TypeAliasTable = @{
	PSFComputer			     = "PSFramework.Parameter.ComputerParameter"
	PSFComputerParameter	 = "PSFramework.Parameter.ComputerParameter"
	psfrgx				     = "PSFramework.Utility.RegexHelper"
}

Set-PSFTypeAlias -Mapping $TypeAliasTable