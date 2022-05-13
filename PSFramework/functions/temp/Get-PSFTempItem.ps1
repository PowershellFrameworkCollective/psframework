function Get-PSFTempItem {
<#
	.SYNOPSIS
		List existing temporary items.
	
	.DESCRIPTION
		List existing temporary items.
	
	.PARAMETER Name
		Name of the item to filter by.
		Defaults to '*'
	
	.PARAMETER ModuleName
		Name of the module to filter by.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-PSFTempItem
	
		List all existing temporary items.
#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
		[string]
		$Name = '*',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[string]
		$ModuleName = '*'
	)
	
	process {
		($script:tempItems.Get($ModuleName, $Name))
	}
}
