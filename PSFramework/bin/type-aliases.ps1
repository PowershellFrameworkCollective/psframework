# Obtain a reference to the TypeAccelerators type
$TAType = [psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")

# Define our type aliases
$TypeAliasTable = @{
	PSFComputer  = "PSFramework.Parameter.ComputerParameter"
	psfrgx       = "PSFramework.Utility.RegexHelper"
}

# Add all type aliases
foreach ($TypeAlias in $TypeAliasTable.Keys)
{
	try
	{
		$TAType::Add($TypeAlias, $TypeAliasTable[$TypeAlias])
	}
	catch
	{
	}
}
