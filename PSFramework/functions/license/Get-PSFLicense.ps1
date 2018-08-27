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
		PS C:\> Get-PSFLicense -LicenseType Commercial -PoductType Library
	
		Returns a list of all registered licenses for products that have commercial licenses and are libraries.
#>
	
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
	
	$licenses = [PSFramework.License.LicenseHost]::Get() | Where-Object { ($_.Product -like $Filter) -and ($_.Manufacturer -like $Manufacturer) }
	if ($PSBoundParameters.ContainsKey("ProductType"))
	{
		$temp = $licenses
		$licenses = @()
		
		:main foreach ($l in $temp)
		{
			foreach ($type in $ProductType)
			{
				if ($l.ProductType -eq $type)
				{
					$licenses += $l
					continue main
				}
			}
		}
	}
	
	if ($PSBoundParameters.ContainsKey("LicenseType"))
	{
		$licenses | Where-Object { ($_.LicenseType.ToString() -match $LicenseType.ToString()) -and ($_.Manufacturer -like $Manufacturer) -and ($_.Product -like $Filter) }
	}
	else
	{
		$licenses | Where-Object { ($_.Manufacturer -like $Manufacturer) -and ($_.Product -like $Filter) }
	}
}
