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
		$internalExecutionContext = [PSFramework.Utility.UtilityHost]::GetExecutionContextFromTLS()
		$topLevelSessionState = [PSFramework.Utility.UtilityHost]::GetPrivateProperty('TopLevelSessionState', $internalExecutionContext)
		$globalScope = [PSFramework.Utility.UtilityHost]::GetPrivateProperty('GlobalScope', $topLevelSessionState)
		$addMethod = $globalScope.GetType().GetMethod('AddType', [System.Reflection.BindingFlags]'Instance, NonPublic')
	}
	process
	{
		foreach ($typeObject in $ClassType)
		{
			$arguments = @($typeObject.Name, $typeObject)
			$addMethod.Invoke($globalScope, $arguments)
		}
	}
}