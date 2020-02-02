function Export-PSFModuleClass
{
<#
	.SYNOPSIS
		Exports a module-defined PowerShell class irrespective of how the module is being imported.
	
	.DESCRIPTION
		Exports a module-defined PowerShell class irrespective of how the module is being imported.
		This avoids having to worry about how the module is being imported.
	
		Please beware the risk of class-name-collisions however.
	
	.PARAMETER ClassType
		The types to publish.
	
	.EXAMPLE
		PS C:\> Export-PSFModuleClass -ClassType ([MyModule_MyClass])
	
		Publishes the class MyModule_MyClass, making it available outside of your module.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[System.Type[]]
		$ClassType
	)
	
	begin
	{
		$mapping = @{ }
		
	}
	process
	{
		foreach ($typeObject in $ClassType)
		{
			$mapping[$typeObject.Name] = $typeObject
		}
	}
	end
	{
		Set-PSFTypeAlias -Mapping $mapping
	}
}