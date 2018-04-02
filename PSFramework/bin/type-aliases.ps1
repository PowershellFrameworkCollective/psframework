# Define our type aliases
$TypeAliasTable = @{
	PSFComputer			   = "PSFramework.Parameter.ComputerParameter"
	PSFComputerParameter   = "PSFramework.Parameter.ComputerParameter"
	psfrgx				   = "PSFramework.Utility.RegexHelper"
	PSFTimeSpan		       = "PSFramework.Parameter.TimeSpanParameter"
	PSFTimeSpanParameter   = "PSFramework.Parameter.TimeSpanParameter"
}

Set-PSFTypeAlias -Mapping $TypeAliasTable