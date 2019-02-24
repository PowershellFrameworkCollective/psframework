function Register-PSFSessionObjectType
{
<#
	.SYNOPSIS
		Registers a new type as a live session object.
	
	.DESCRIPTION
		Registers a new type as a live session object.
		This is used in the session container object, used to pass through multiple types of connection objects to a single PSFComputer parameterclassed parameter.
	
	.PARAMETER DisplayName
		The display name for the type.
		Pick anything that intuitively points at what the object is.
	
	.PARAMETER TypeName
		The full name of the type.
	
	.EXAMPLE
		PS C:\> Register-PSFSessionObjectType -DisplayName 'PSSession' -TypeName 'System.Management.Automation.Runspaces.PSSession'
	
		Registers the type 'System.Management.Automation.Runspaces.PSSession' under the name of 'PSSession'.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$DisplayName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$TypeName
	)
	
	process
	{
		[PSFramework.ComputerManagement.ComputerManagementHost]::KnownSessionTypes[$TypeName] = $DisplayName
	}
}