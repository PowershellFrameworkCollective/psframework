function Register-PSFArgumentTransformationScriptblock {
	<#
	.SYNOPSIS
		Registers an input conversion scriptblock for use in Parameter Binding.
	
	.DESCRIPTION
		Registers an input conversion scriptblock for use in Parameter Binding.
		It receives exactly one input - the parameter input to convert.
		The scriptblock is expected to return the result in the expected type - only the first value returned is used.

		If this conversion failes, it will still try to convert it with the default PowerShell type conversion.

		The scriptblock registered here can later be referenced in your commands as a parameter attribute like this:
		[PsfScriptTransformation("MyModule.User", [MyModule.User])]

		- The first value is the name specified here.
		- The second value is the expected data type.
	
	.PARAMETER Name
		Name of the scriptblock.
		The name can be arbitrary, but naming should consider the potential to conflict with other modules.
	
	.PARAMETER Scriptblock
		The script logic performing the conversion.
	
	.EXAMPLE
		PS C:\> Register-PSFArgumentTransformationScriptblock -Name MyModule.User -Scriptblock $conversion
		
		Registers the input conversion as defined in $conversion under "MyModule.User"
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Name,

		[Parameter(Mandatory = $true, Position = 1)]
		[scriptblock]
		$Scriptblock
	)
	process {
		[PSFramework.Utility.ScriptTransformationAttribute]::Conversions[$Name] = $Scriptblock
	}
}