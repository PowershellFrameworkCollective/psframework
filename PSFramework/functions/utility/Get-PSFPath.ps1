function Get-PSFPath
{
<#
	.SYNOPSIS
		Access a configured path.
	
	.DESCRIPTION
		Access a configured path.
		Paths can be configured using Set-PSFPath or using the configuration system.
		To register a path using the configuration system create a setting key named like this:
		"PSFramework.Path.<PathName>"
		For example the following setting points at the temp path:
		"PSFramework.Path.Temp"
	
	.PARAMETER Name
		Name of the path to retrieve.
	
	.EXAMPLE
		PS C:\> Get-PSFPath -Name 'temp'
	
		Returns the temp path.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Name
	)
	
	process
	{
		Get-PSFConfigValue -FullName "PSFramework.Path.$Name"
	}
}