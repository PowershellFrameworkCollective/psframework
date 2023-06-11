function Get-PSFMessageColorTransform {
	<#
	.SYNOPSIS
		Lists registered message color rules.
	
	.DESCRIPTION
		Lists registered message color rules.
	
	.PARAMETER Name
		Name by which to filter the rules.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-PSFMessageColorTransform
		
		Lists all registered message color rules.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name = '*'
	)
	process {
		$([PSFramework.Message.MessageHost]::ColorTransforms.Values) | Where-Object Name -Like $Name
	}
}