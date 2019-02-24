function Get-PSFFeature
{
<#
	.SYNOPSIS
		Returns a list of all registered features.
	
	.DESCRIPTION
		Returns a list of all registered features.
	
	.PARAMETER Name
		The name to filter by.
	
	.EXAMPLE
		PS C:\> Get-PSFFeature
	
		Returns all features registered.
#>
	[CmdletBinding()]
	param (
		[string]
		$Name = "*"
	)
	
	process
	{
		[PSFramework.Feature.FeatureHost]::Features.Values | Where-Object Name -Like $Name
	}
}