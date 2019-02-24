function Register-PSFFeature
{
<#
	.SYNOPSIS
		Registers a feature for use in the PSFramework Feature Flag System.
	
	.DESCRIPTION
		Registers a feature for use in the PSFramework Feature Flag System.
		This allows offering a common interface for enabling and disabling features on-demand.
		Typical use-cases:
		- Experimental Features
		- Reverting breaking behavior on a per-module basis.
	
	.PARAMETER Name
		The name of the feature to register.
		Feature names are scoped globally, so please prefix by your own module's name.
	
	.PARAMETER Description
		A description of the feature, so users can discover what it is about.
	
	.PARAMETER NotGlobal
		Disables global flags for this feature.
		By default, features can be enabled or disabled on a global scope.
	
	.PARAMETER NotModuleSpecific
		Disables module specific feature flags.
		By default, individual modules can override the global settings either way.
		This may not really be applicable for all features however.
	
	.PARAMETER Owner
		The name of the module owning the feature.
		Autodiscovery is attempted, but it is recommended to explicitly specify the owning module's name.
	
	.EXAMPLE
		PS C:\> Register-PSFFeature -Name 'MyModule.DividebyZeroExp' -Description 'Attempt to divide by zero' -Owner MyModule
	
		Registers the feature under its owning module and adds a nice description.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[string]
		$Description,
		
		[switch]
		$NotGlobal,
		
		[switch]
		$NotModuleSpecific,
		
		[string]
		$Owner = (Get-PSCallStack)[1].InvocationInfo.MyCommand.ModuleName
	)
	
	begin
	{
		$featureObject = New-Object PSFramework.Feature.FeatureItem -Property @{
			Name = $Name
			Owner = $Owner
			Global = (-not $NotGlobal)
			ModuleSpecific = (-not $NotModuleSpecific)
			Description = $Description
		}
	}
	process
	{
		[PSFramework.Feature.FeatureHost]::Features[$Name] = $featureObject
	}
}