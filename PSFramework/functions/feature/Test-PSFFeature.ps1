function Test-PSFFeature
{
<#
	.SYNOPSIS
		Tests whether a given feature has been enabled.
	
	.DESCRIPTION
		Tests whether a given feature has been enabled.
		Use this within the feature-owning module to determine, whether a feature should be enabled or not.
	
	.PARAMETER Name
		The feature to test for.
	
	.PARAMETER ModuleName
		The name of the module that seeks to use the feature.
		Must be specified in order to determine module-specific flags.
	
	.EXAMPLE
		PS C:\> Test-PSFFeature -Name PSFramework.InheritEnableException -ModuleName SPReplicator
	
		Tests whether the module SPReplicator has enabled the Enable Exception Inheritance feature.
#>
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		#[PsfValidateSet(TabCompletion = 'PSFramework.Feature.Name')]
		[parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[string]
		$ModuleName
	)
	
	begin
	{
		$featureItem = Get-PSFFeature -Name $Name
	}
	process
	{
		if (-not $featureItem.Global) { [PSFramework.Feature.FeatureHost]::ReadModuleFlag($Name, $ModuleName) }
		else { [PSFramework.Feature.FeatureHost]::ReadFlag($Name, $ModuleName) }
	}
}