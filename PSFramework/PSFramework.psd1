@{
	
	# Script module or binary module file associated with this manifest
	RootModule = 'PSFramework.psm1'
	
	# Version number of this module.
	ModuleVersion = '1.9.310'
	
	# ID used to uniquely identify this module
	GUID = '8028b914-132b-431f-baa9-94a6952f21ff'
	
	# Author of this module
	Author = 'Friedrich Weinmann'
	
	# Company or vendor of this module
	CompanyName = 'PowerShell Framework Collective'
	
	# Copyright statement for this module
	Copyright = '(c) Friedrich Weinmann 2017. All rights reserved.'
	
	# Description of the functionality provided by this module
	Description = 'General Scripting Framework, providing PowerShell-specific infrastructure for other modules.'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '3.0'
	
	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @("bin\PSFramework.dll")
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\PSFramework.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @('xml\PSFramework.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport  = @(
		'Add-PSFFilterCondition'
		'Add-PSFLoggingProviderRunspace'
		'Clear-PSFMessage'
		'Clear-PSFResultCache'
		'Compare-PSFArray'
		'ConvertFrom-PSFArray'
		'ConvertFrom-PSFClixml'
		'ConvertTo-PSFClixml'
		'Disable-PSFConsoleInterrupt'
		'Disable-PSFLoggingProvider'
		'Disable-PSFTaskEngineTask'
		'Enable-PSFConsoleInterrupt'
		'Enable-PSFTaskEngineTask'
		'Export-PSFClixml'
		'Export-PSFConfig'
		'Export-PSFModuleClass'
		'Get-PSFCallback'
		'Get-PSFConfig'
		'Get-PSFConfigValue'
		'Get-PSFDynamicContentObject'
		'Get-PSFFeature'
		'Get-PSFFilterCondition'
		'Get-PSFFilterConditionSet'
		'Get-PSFLicense'
		'Get-PSFLocalizedString'
		'Get-PSFLoggingError'
		'Get-PSFLoggingProvider'
		'Get-PSFLoggingProviderInstance'
		'Get-PSFMessage'
		'Get-PSFMessageColorTransform'
		'Get-PSFMessageLevelModifier'
		'Get-PSFPath'
		'Get-PSFPipeline'
		'Get-PSFResultCache'
		'Get-PSFRunspace'
		'Get-PSFScriptblock'
		'Get-PSFTaskEngineCache'
		'Get-PSFTaskEngineTask'
		'Get-PSFTempItem'
		'Get-PSFTypeSerializationData'
		'Get-PSFUserChoice'
		'Import-PSFClixml'
		'Import-PSFCmdlet'
		'Import-PSFConfig'
		'Import-PSFLocalizedString'
		'Import-PSFLoggingProvider'
		'Import-PSFPowerShellDataFile'
		'Install-PSFLoggingProvider'
		'Invoke-PSFCommand'
		'Invoke-PSFFilter'
		'Join-PSFPath'
		'New-PSFFilter'
		'New-PSFFilterCondition'
		'New-PSFFilterConditionSet'
		'New-PSFLicense'
		'New-PSFMessageLevelModifier'
		'New-PSFSessionContainer'
		'New-PSFSupportPackage'
		'New-PSFTempDirectory'
		'New-PSFTempFile'
		'New-PSFTempItem'
		'New-PSFTeppCompletionResult'
		'New-PSFThrottle'
		'Register-PSFArgumentTransformationScriptblock'
		'Register-PSFCallback'
		'Register-PSFConfig'
		'Register-PSFConfigSchema'
		'Register-PSFConfigValidation'
		'Register-PSFFeature'
		'Register-PSFLoggingProvider'
		'Register-PSFMessageColorTransform'
		'Register-PSFMessageEvent'
		'Register-PSFMessageTransform'
		'Register-PSFParameterClassMapping'
		'Register-PSFRunspace'
		'Register-PSFSessionObjectType'
		'Register-PSFTaskEngineTask'
		'Register-PSFTempProvider'
		'Register-PSFTeppArgumentCompleter'
		'Register-PSFTeppScriptblock'
		'Register-PSFTypeSerializationData'
		'Remove-PSFAlias'
		'Remove-PSFConfig'
		'Remove-PSFLicense'
		'Remove-PSFLoggingProviderRunspace'
		'Remove-PSFMessageLevelModifier'
		'Remove-PSFTempItem'
		'Reset-PSFConfig'
		'Resolve-PSFDefaultParameterValue'
		'Resolve-PSFItem'
		'Resolve-PSFPath'
		'Select-PSFConfig'
		'Select-PSFPropertyValue'
		'Set-PSFDynamicContentObject'
		'Set-PSFFeature'
		'Set-PSFLoggingProvider'
		'Set-PSFPath'
		'Set-PSFResultCache'
		'Set-PSFScriptblock'
		'Set-PSFTaskEngineCache'
		'Set-PSFTeppResult'
		'Set-PSFTypeAlias'
		'Start-PSFRunspace'
		'Stop-PSFFunction'
		'Stop-PSFRunspace'
		'Test-PSFFeature'
		'Test-PSFFilter'
		'Test-PSFFunctionInterrupt'
		'Test-PSFLanguageMode'
		'Test-PSFParameterBinding'
		'Test-PSFPowerShell'
		'Test-PSFTaskEngineCache'
		'Test-PSFTaskEngineTask'
		'Unregister-PSFCallback'
		'Unregister-PSFConfig'
		'Unregister-PSFMessageColorTransform'
		'Wait-PSFMessage'
		'Write-PSFHostColor'
		'Write-PSFMessageProxy'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport	       = @(
		'ConvertTo-PSFHashtable'
		'Invoke-PSFCallback'
		'Invoke-PSFProtectedCommand'
		'Remove-PSFNull'
		'Select-PSFObject'
		'Set-PSFConfig'
		'Set-PSFObjectOrder'
		'Test-PSFShouldProcess'
		'Write-PSFMessage'
	)
	
	# Variables to export from this module
	VariablesToExport = ''
	
	# Aliases to export from this module
	AliasesToExport = @(
		'Get-LastResult'
		'glr'
		'Sort-PSFObject'
		'Was-Bound'
	)
	
	# List of all modules packaged with this module
	ModuleList = @()
	
	# List of all files packaged with this module
	FileList = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			# Prerelease = 'preview3'
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('scripting', 'infrastructure', 'logging', 'configuration', 'PSEdition_Core', 'PSEdition_Desktop', 'Linux', 'Mac')
			
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/PowershellFrameworkCollective/psframework/blob/master/LICENSE'
			
			# A URL to the main website for this project.
			ProjectUri = 'http://psframework.org'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/PowershellFrameworkCollective/psframework/blob/master/PSFramework/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}