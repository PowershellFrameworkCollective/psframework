function Remove-PSFTempItem {
<#
	.SYNOPSIS
		Removes temporary items.
	
	.DESCRIPTION
		Removes temporary items.
		This not only removes them from memory, but also invokes the item's deletion logic, removing temporary files, deleting temporary user accounts, etc.
	
	.PARAMETER Name
		Name of the temporary item to remove.
	
	.PARAMETER ModuleName
		Name of the module to filter by.
	
	.PARAMETER ClearExpired
		Globally remove all temporary items that have expired.
	
	.EXAMPLE
		PS C:\> Remove-PSFTempItem -ClearExpired
	
		Globally removes all temporary items that have expired.
	
	.EXAMPLE
		PS C:\> Get-PSFTempItem | Remove-PSFTempItem
	
		Remove ALL temporary items, irrespective of whether they are still needed or not.
	
	.EXAMPLE
		PS C:\> Remove-PSFTempItem -Name configFile -Module FWManager
	
		Removes the temp item "configFile" of the module "FWManager"
	
	.EXAMPLE
		PS C:\> Remove-PSFTempItem -Name *beer* -Module Fridge
	
		Removes all temporary items containing the word "beer" that are associated with the module "Fridge".
		Try not to get too drunk.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'targeted')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName = 'targeted')]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'targeted')]
		[Alias('Module')]
		[string]
		$ModuleName,
		
		[Parameter(ParameterSetName = 'expired')]
		[switch]
		$ClearExpired
	)
	
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'expired' { $script:tempItems.ClearExpired() }
			'targeted' {
				foreach ($tempItem in $script:tempItems.Get($ModuleName, $Name)) {
					try { $tempItem.Delete() }
					catch { $PSCmdlet.WriteError($_) }
				}
			}
		}
	}
}