@{
	
	# Script module or binary module file associated with this manifest
	RootModule = 'PSFramework.psm1'
	
	# Version number of this module.
	ModuleVersion = '1.13.416'
	
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
		'Add-PSFRunspaceWorker'
		'Add-PSFTeppCompletion'
		'Clear-PSFMessage'
		'Clear-PSFresultCache'
		'Compare-PSFArray'
		'ConvertFrom-PSFArray'
		'ConvertFrom-PSFClixml'
		'ConvertTo-PSFClixml'
		'ConvertTo-PSFPsd1'
		'Disable-PSFConsoleInterrupt'
		'Disable-PSFLoggingProvider'
		'Disable-PSFTaskEngineTask'
		'Enable-PSFConsoleInterrupt'
		'Enable-PSFTaskEngineTask'
		'Export-PSFClixml'
		'Export-PSFConfig'
		'Export-PSFJson'
		'Export-PSFModuleClass'
		'Export-PSFPowerShellDataFile'
		'Get-PSFCallback'
		'Get-PSFConfig'
		'Get-PSFConfigValue'
		'Get-PSFDynamicContentObject'
		'Get-PSFFeature'
		'Get-PSFFileContent'
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
		'Get-PSFRunspaceWorkflow'
		'Get-PSFRunspaceWorker'
		'Get-PSFScriptblock'
		'Get-PSFTaskEngineCache'
		'Get-PSFTaskEngineTask'
		'Get-PSFTempItem'
		'Get-PSFTeppCompletion'
		'Get-PSFTypeSerializationData'
		'Get-PSFUserChoice'
		'Import-PSFClixml'
		'Import-PSFCmdlet'
		'Import-PSFConfig'
		'Import-PSFJson'
		'Import-PSFLocalizedString'
		'Import-PSFLoggingProvider'
		'Import-PSFPowerShellDataFile'
		'Install-PSFLoggingProvider'
		'Invoke-PSFCommand'
		'Invoke-PSFFilter'
		'Invoke-PSFRunspace'
		'Join-PSFPath'
		'New-PSFFilter'
		'New-PSFFilterCondition'
		'New-PSFFilterConditionSet'
		'New-PSFHashtable'
		'New-PSFLicense'
		'New-PSFMessageLevelModifier'
		'New-PSFRunspaceWorkflow'
		'New-PSFSessionContainer'
		'New-PSFSupportPackage'
		'New-PSFTempDirectory'
		'New-PSFTempFile'
		'New-PSFTempItem'
		'New-PSFTeppCompletionResult'
		'New-PSFThrottle'
		'Read-PSFRunspaceQueue'
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
		'Register-PSFPsd1Converter'
		'Register-PSFRunspace'
		'Register-PSFSessionObjectType'
		'Register-PSFSupportDataProvider'
		'Register-PSFTaskEngineTask'
		'Register-PSFTempProvider'
		'Register-PSFTeppArgumentCompleter'
		'Register-PSFTeppScriptblock'
		'Register-PSFTypeAssemblyMapping'
		'Register-PSFTypeSerializationData'
		'Remove-PSFAlias'
		'Remove-PSFConfig'
		'Remove-PSFLicense'
		'Remove-PSFLoggingProviderRunspace'
		'Remove-PSFMessageLevelModifier'
		'Remove-PSFRunspaceWorkflow'
		'Remove-PSFTempItem'
		'Remove-PSFTeppCompletion'
		'Reset-PSFConfig'
		'Resolve-PSFDefaultParameterValue'
		'Resolve-PSFItem'
		'Resolve-PSFPath'
		'Select-PSFConfig'
		'Select-PSFPropertyValue'
		'Set-PSFDynamicContentObject'
		'Set-PSFFeature'
		'Set-PSFFileContent'
		'Set-PSFLoggingProvider'
		'Set-PSFPath'
		'Set-PSFResultCache'
		'Set-PSFScriptblock'
		'Set-PSFTaskEngineCache'
		'Set-PSFTeppResult'
		'Set-PSFTypeAlias'
		'Start-PSFRunspace'
		'Start-PSFRunspaceWorkflow'
		'Start-PSFRunspaceWorker'
		'Stop-PSFFunction'
		'Stop-PSFRunspace'
		'Stop-PSFRunspaceWorkflow'
		'Stop-PSFRunspaceWorker'
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
		'Wait-PSFRunspaceWorkflow'
		'Write-PSFHostColor'
		'Write-PSFMessageProxy'
		'Write-PSFRunspaceQueue'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport	       = @(
		'Assert-PSFInternalCommand'
		'ConvertTo-PSFHashtable'
		'Invoke-PSFCallback'
		'Invoke-PSFProtectedCommand'
		'Remove-PSFNull'
		'Select-PSFObject'
		'Set-PSFConfig'
		'Set-PSFObjectOrder'
		'Test-PSFShouldProcess'
		'Update-PSFTeppCompletion'
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