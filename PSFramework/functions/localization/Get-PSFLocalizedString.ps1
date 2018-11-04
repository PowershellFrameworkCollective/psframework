function Get-PSFLocalizedString
{
<#
	.SYNOPSIS
		Returns the localized strings of a module.
	
	.DESCRIPTION
		Returns the localized strings of a module.
		By default, it creates a variable that has access to each localized string in the module (with string name as propertyname).
		Alternatively, by specifying a specific string, that string can instead be returned.
	
	.PARAMETER Module
		The name of the module to map.
	
	.PARAMETER Name
		The name of the string to return
	
	.EXAMPLE
		PS C:\> Get-PSFLocalizedString -Module 'MyModule'
	
		Returns an object that can be used to access any localized string.
	
	.EXAMPLE
		PS C:\> Get-PSFLocalizedString -Module 'MyModule' -Name 'ErrorValidation'
	
		Returns the string for the module 'MyModule'  that is stored under the 'ErrorValidation'  name.
#>
	[OutputType([PSFramework.Localization.LocalStrings], ParameterSetName = 'Default')]
	[OutputType([System.String], ParameterSetName = 'Name')]
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Default')]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string]
		$Name
	)
	
	process
	{
		switch ($PSCmdlet.ParameterSetName)
		{
			'Default' { New-Object PSFramework.Localization.LocalStrings($Module) }
			'Name' { (New-Object PSFramework.Localization.LocalStrings($Module)).$Name }
		}
	}
}