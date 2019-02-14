function Register-PSFConfigSchema
{
<#
	.SYNOPSIS
		Register new schemas for ingersting configuration data.
	
	.DESCRIPTION
		Register new schemas for ingersting configuration data.
		This can be used to dynamically extend the configuration system and add new file types as supported input.
	
	.PARAMETER Name
		The name of the Schema to register.
	
	.PARAMETER Schema
		The Schema Code to register.
	
	.EXAMPLE
		PS C:\> Register-PSFConfigSchema -Name Default -Schema $scriptblock
	
		Registers the scriptblock stored in $scriptblock under 'Default'
#>
	[CmdletBinding()]
	Param (
		[string]
		$Name,
		
		[ScriptBlock]
		$Schema
	)
	
	process
	{
		[PSFramework.Configuration.ConfigurationHost]::Schemata[$Name] = $Schema
	}
}