function Set-PSFTypeAlias
{
<#
	.SYNOPSIS
		Registers or updates an alias for a .NET type.
	
	.DESCRIPTION
		Registers or updates an alias for a .NET type.
		Use this function during module import to create shortcuts for typenames users can be expected to interact with directly.
	
	.PARAMETER AliasName
		The short and useful alias for the type.
	
	.PARAMETER TypeName
		The full name of the type.
		Example: 'System.IO.FileInfo'
	
	.PARAMETER Mapping
		A hashtable of alias to typename mappings.
		Useful to registering a full set of type aliases.
	
	.EXAMPLE
		PS C:\> Set-PSFTypeAlias -AliasName 'file' -TypeName 'System.IO.File'
	
		Creates an alias for the type 'System.IO.File' named 'file'
	
	.EXAMPLE
		PS C:\> Set-PSFTypeAlias -Mapping @{
			file = 'System.IO.File'
			path = 'System.IO.Path'
		}
	
		Creates an alias for the type 'System.IO.File' named 'file'
		Creates an alias for the type 'System.IO.Path' named 'path'
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(DefaultParameterSetName = 'Name', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFTypeAlias')]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Name', ValueFromPipelineByPropertyName = $true)]
		[string]
		$AliasName,
		
		[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Name', ValueFromPipelineByPropertyName = $true)]
		[string]
		$TypeName,
		
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Hashtable')]
		[hashtable]
		$Mapping
	)
	
	begin
	{
		# Obtain a reference to the TypeAccelerators type
		$TypeAcceleratorType = [psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")
	}
	process
	{
		foreach ($key in $Mapping.Keys)
		{
			$TypeAcceleratorType::Add($key, $Mapping[$key])
		}
		if ($AliasName)
		{
			$TypeAcceleratorType::Add($AliasName, $TypeName)
		}
	}
}