function Set-PSFFeature
{
<#
	.SYNOPSIS
		Toggles a feature on or off.
	
	.DESCRIPTION
		Toggles a feature on or off.
		This controls the flags for optional features a module might offer.
	
		Features can be controlled globally or specific to a module that tries to consume it.
		Module specific settings can override global settings, if a feature supports both global and module flags.
	
	.PARAMETER Name
		The name of the feature to set.
	
	.PARAMETER Value
		The value to set it to.
	
	.PARAMETER ModuleName
		The module it should apply to.
		Specifying this parameter sets the flag only for the module specified.
	
	.EXAMPLE
		PS C:\> Set-PSFFeature -Name 'PSFramework.InheritEnableException' -Value $true -ModuleName SPReplicator
	
		This sets the flag for the Enable Exception Inheritance Name to $true, but only applies to the module SPReplicator.
	
	.EXAMPLE
		PS C:\> Set-PSFFeature -Name 'MyModule.Feierabend' -Value $true
	
		This enables the global flag for the MyModule.Feierabend feature.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		#[PsfValidateSet(TabCompletion = 'PSFramework.Feature.Name')]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[bool]
		$Value,
		
		[string]
		$ModuleName
	)
	process
	{
		foreach ($featureItem in $Name)
		{
			if ($ModuleName)
			{
				[PSFramework.Feature.FeatureHost]::WriteModuleFlag($ModuleName, $Name, $Value)
			}
			else
			{
				[PSFramework.Feature.FeatureHost]::WriteGlobalFlag($Name, $Value)
			}
		}
	}
}