function Remove-PSFLicense
{
<#
	.SYNOPSIS
		Removes a registered license from the license store
	
	.DESCRIPTION
		Removes a registered license from the license store
	
	.PARAMETER License
		The license to remove
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Get-PSFLicense "FooBar" | Remove-PSFLicense
	
		Removes the license for the product "FooBar" from the license store.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Remove-PSFLicense')]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[PSFramework.License.License[]]
		$License,
		
		[switch]
		$EnableException
	)
	
	Process
	{
		foreach ($licenseObject in $License)
		{
			if (Test-PSFShouldProcess -Action 'Remove License' -Target $licenseObject -PSCmdlet $PSCmdlet)
			{
				try { [PSFramework.License.LicenseHost]::Remove($licenseObject) }
				catch
				{
					Stop-PSFFunction -Message "Failed to remove license" -ErrorRecord $_ -EnableException $EnableException -Target $licenseObject -Continue
				}
			}
		}
	}
}
