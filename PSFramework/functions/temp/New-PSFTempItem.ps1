function New-PSFTempItem {
<#
	.SYNOPSIS
		Creates a temporary item
	
	.DESCRIPTION
		Creates a temporary item.
		This is a generically extensible item that requires a provider - a plugin - that determines what it actually means.
		Depending on the implementation, this could be a temporary user account, a temporary database, a temporary ... anything.
	
		Use Register-PSFTempProvider to define a temporary item provider.
	
	.PARAMETER Name
		The name of the temporary item.
		Used for identifying the item, but need not be particularly unique otherwise.
	
	.PARAMETER ProviderName
		Name of the provider implementing the actual logic.
		Use Register-PSFTempProvider to define one.
	
	.PARAMETER Data
		The information needed to generate the temporary item.
		What information is needed by the provider depends on the provider implementation itself.
	
	.PARAMETER Timeout
		How long into the future this item is valid.
		Expired temporary items can be conveniently cleaned up using Remove-PSFTempItem.
	
	.PARAMETER ModuleName
		Name of the module the temp item belongs to.
		If called from within a module, this value will be detected automatically and needs not be specified.
	
	.EXAMPLE
		PS C:\> New-PSFTempItem -Name 'userA' -ProviderName 'aduser' -Data @{ OU = 'OU=TempUser,OU=Company,DC=Contoso,DC=com' }
	
		Create a temporary AD user named userA.
		Requires a temporary item provider named aduser.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PsfValidateScript('PSFramework.Validate.SafeName', ErrorString = 'PSFramework.Validate.SafeName')]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('PSFramework.Temp.ProviderName')]
		[PsfValidateSet(TabCompletion = 'PSFramework.Temp.ProviderName')]
		[string]
		$ProviderName,
		
		[Parameter(Mandatory = $true)]
		[hashtable]
		$Data,
		
		[PSFDateTime]
		$Timeout,
		
		[string]
		$ModuleName = [PSFramework.Utility.UtilityHost]::GetCallerInfo(1).CallerModule
	)
	
	process {
		$provider = $script:tempItems.Providers[$ProviderName]
		try { $creationData = $provider.CreationScript.Invoke($Data) }
		catch { $PSCmdlet.ThrowTerminatingError($_) }
		
		$tempItem = [PSFramework.Temp.TempItemGeneric]::new($Name, $ModuleName, $ProviderName, $Data, $script:tempItems, $creationData)
		if ($Timeout) { $tempItem.Timeout = $Timeout }
		$creationData
	}
}