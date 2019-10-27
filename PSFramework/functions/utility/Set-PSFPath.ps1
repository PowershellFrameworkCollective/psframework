function Set-PSFPath
{
<#
	.SYNOPSIS
		Configures or updates a path under a name.
	
	.DESCRIPTION
		Configures or updates a path under a name.
		The path can be persisted using the "-Register" command.
		Paths setup like this can be retrieved using Get-PSFPath.
	
	.PARAMETER Name
		Name the path should be stored under.
	
	.PARAMETER Path
		The path that should be returned under the name.
	
	.PARAMETER Register
		Registering a path in order for it to persist across sessions.
	
	.PARAMETER Scope
		The configuration scope it should be registered under.
		Defaults to UserDefault.
		Configuration scopes are the default locations configurations are being stored at.
		For more details see:
		https://psframework.org/documentation/documents/psframework/configuration/persistence-location.html
	
	.EXAMPLE
		PS C:\> Set-PSFPath -Name 'temp' -Path 'C:\temp'
	
		Configures C:\temp as the current temp path. (does not override $env:temp !)
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(ParameterSetName = 'Register', Mandatory = $true)]
		[switch]
		$Register,
		
		[Parameter(ParameterSetName = 'Register')]
		[PSFramework.Configuration.ConfigScope]
		$Scope = [PSFramework.Configuration.ConfigScope]::UserDefault
	)
	
	process
	{
		Set-PSFConfig -FullName "PSFramework.Path.$Name" -Value $Path
		if ($Register) { Register-PSFConfig -FullName "PSFramework.Path.$Name" -Scope $Scope }
	}
}