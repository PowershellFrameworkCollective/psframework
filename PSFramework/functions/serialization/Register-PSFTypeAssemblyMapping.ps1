function Register-PSFTypeAssemblyMapping {
	<#
	.SYNOPSIS
		Adds a mapping path for assembly resolution when deserializing objects.
	
	.DESCRIPTION
		Adds a mapping path for assembly resolution when deserializing objects.

		THIS ONLY APPLIES TO OBJECTS THAT USE THE PSFRAMEWORK TYPE CONVERTER!

		When sending objects over process boundaries (e.g. when remoting or using Import-/Export-PSFClixml),
		objects get converted to XML and reconstituted / deserialized on the other end.
		This leads to "Deserialized.*" objects that have most of the properties and none of the methods.

		Using a PSTypeConverter as provided by the PSFramework, this fate can be avoided:
		+ Get-PSFTypeSerializationData
		+ Register-PSFTypeSerializationData
		Can provide your own types a conversion path, that allows them to survive this process unharmed,
		by telling PowerShell how to do the conversion.

		This system is not quite perfect, however, as by default we need the exact same assembly (name, version, etc.) on both ends.
		Different version numbers? Changed the name? Tough luck ...

		This is where the Assembly Mapping feature comes in, assuming you use the default PSFramework type converter:
		Use this command to tell the system that just the simple name is enough, or point an old name to a new name!

		Redirection only happens when the originally expected assembly is not available.
	
	.PARAMETER Name
		Full name or regex pattern for an assembly name.
		The name of the assembly you want to point to a new assembly.
	
	.PARAMETER Assembly
		The new assembly to use instead of the one under the previous name.
	
	.PARAMETER ByShortName
		The assembly with this specified short name uses only its short name to match the destination assembly.
		Use this to ignore issues with changing assembly version numbers.
	
	.EXAMPLE
		PS C:\> Register-PSFTypeAssemblyMapping -Name '1s445vjt.n1r, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null' -Assembly ([Foo.Bar].Assembly)
		
		Redirects requests for '1s445vjt.n1r, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null' to the assembly implementing the type [Foo.Bar].

	.EXAMPLE
		PS C:\> Register-PSFTypeAssemblyMapping -Name '^MyProject,' -Assembly ([MyProject.User].Assembly)

		Redirects requests for assemblies starting with the name 'MyProject,' to the assembly implementing [MyProject.User].

	.EXAMPLE
		PS C:\> Register-PSFTypeAssemblyMapping -Name MyProject

		All requests for the assembly with the shortname "MyProject" will now ignore assembly versions.
	#>
	[CmdletBinding()]
	param (
		[PSFramework.Validation.PsfValidateTrustedDataAttribute()]
		[Parameter(Mandatory = $true, ParameterSetName = 'Assembly')]
		[string]
		$Name,

		[PSFramework.Validation.PsfValidateTrustedDataAttribute()]
		[Parameter(Mandatory = $true, ParameterSetName = 'Assembly')]
		[System.Reflection.Assembly]
		$Assembly,

		[PSFramework.Validation.PsfValidateTrustedDataAttribute()]
		[Parameter(Mandatory = $true, ParameterSetName = 'ShortName')]
		[string]
		$ByShortName
	)
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'Assembly' {
				[PSFramework.Serialization.SerializationTypeConverter]::AssemblyMapping[$Name] = $Assembly
			}
			'ShortName' {
				[PSFramework.Serialization.SerializationTypeConverter]::AssemblyShortnameMapping[$ByShortName] = $true
			}
		}
	}
}