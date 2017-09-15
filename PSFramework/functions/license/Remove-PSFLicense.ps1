function Remove-PSFLicense
{
<#
	.SYNOPSIS
		Removes a registered license from the license store
	
	.DESCRIPTION
		Removes a registered license from the license store
	
	.PARAMETER License
		The license to remove
	
	.EXAMPLE
		PS C:\> Get-PSFLicense "FooBar" | Remove-PSFLicense
	
		Removes the license for the product "FooBar" from the license store.
#>
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[PSFramework.License.License[]]
		$License,
		
		[switch]
		$EnableException
	)
	
	Begin
	{
		
	}
	Process
	{
		foreach ($l in $License)
		{
			try { [PSFramework.License.LicenseHost]::Remove($l) }
			catch
			{
				Stop-PSFFunction -Message "Failed to remove license" -ErrorRecord $_ -EnableException $EnableException -Target $l -Continue
			}
		}
	}
	End
	{
		
	}
}
