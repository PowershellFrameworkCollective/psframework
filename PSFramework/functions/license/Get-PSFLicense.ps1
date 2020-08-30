function Get-PSFLicense
{
<#
	.SYNOPSIS
		Returns registered licenses
	
	.DESCRIPTION
		Returns all matching licenses from the PSFramework internal license cache.
	
	.PARAMETER Filter
		Default: "*"
		Filters for the name of the product. Uses the -like operator.
	
	.PARAMETER ProductType
		Only licenses of products for any of the specified types are considered.
	
	.PARAMETER LicenseType
		Only licenses of any matching type are returned.
	
	.PARAMETER Manufacturer
		Default: "*"
		Only licenses for products of a matching manufacturer are returned. Uses the -like operator for comparisons.
	
	.EXAMPLE
		PS C:\> Get-PSFLicense *Microsoft*
	
		Returns all registered licenses for products with the string "Microsoft" in their name
	
	.EXAMPLE
		PS C:\> Get-PSFLicense -LicenseType Commercial -ProductType Library
	
		Returns a list of all registered licenses for products that have commercial licenses and are libraries.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding(PositionalBinding = $false, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFLicense')]
	[OutputType([PSFramework.License.License])]
	param (
		[Parameter(Position = 0)]
		[Alias('Product')]
		[String]
		$Filter = "*",
		
		[PSFramework.License.ProductType[]]
		$ProductType,
		
		[PSFramework.License.LicenseType]
		$LicenseType,
		
		[String]
		$Manufacturer = "*"
	)
	
	process
	{
		[PSFramework.License.LicenseHost]::Get() | Where-Object {
			if ($_.Product -notlike $Filter) { return $false }
			if ($_.Manufacturer -notlike $Manufacturer) { return $false }
			if ($ProductType -and ($_.ProductType -notin $ProductType)) { return $false }
			if ($licenseType -and -not ($_.LicenseType -band $LicenseType)) { return $false }
			return $true
		}
	}
}
