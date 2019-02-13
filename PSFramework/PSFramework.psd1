
@{
	
	# Script module or binary module file associated with this manifest
	RootModule = 'PSFramework.psm1'
	
	# Version number of this module.
	ModuleVersion = '1.0.0'
	
	# ID used to uniquely identify this module
	GUID = '8028b914-132b-431f-baa9-94a6952f21ff'
	
	# Author of this module
	Author = 'Friedrich Weinmann'
	
	# Company or vendor of this module
	CompanyName = 'PowerShell Framework Collective'
	
	# Copyright statement for this module
	Copyright = '(c) Friedrich Weinmann 2017. All rights reserved.'
	
	# Description of the functionality provided by this module
	Description = 'A module that provides tools for other modules and scripts'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '3.0'
	
	# Name of the Windows PowerShell host required by this module
	PowerShellHostName = ''
	
	# Minimum version of the Windows PowerShell host required by this module
	PowerShellHostVersion = ''
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '2.0'
	
	# Minimum version of the common language runtime (CLR) required by this module
	CLRVersion = '2.0.50727'
	
	# Processor architecture (None, X86, Amd64, IA64) required by this module
	ProcessorArchitecture = 'None'
	
	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @()
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @("bin\PSFramework.dll")
	
	# Script files (.ps1) that are run in the caller's environment prior to
	# importing this module
	ScriptsToProcess = @()
	
	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\PSFramework.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module
	FormatsToProcess = @('xml\PSFramework.Format.ps1xml')
	
	# Modules to import as nested modules of the module specified in
	# ModuleToProcess
	#NestedModules = @()
	
	# Functions to export from this module
	FunctionsToExport = @(
		'Clear-PSFResultCache',
		'ConvertFrom-PSFClixml',
		'ConvertTo-PSFClixml',
		'ConvertTo-PSFHashtable',
		'Disable-PSFTaskEngineTask',
		'Enable-PSFTaskEngineTask',
		'Export-PSFClixml',
		'Export-PSFConfig',
		'Get-PSFConfig',
		'Get-PSFConfigValue',
		'Get-PSFDynamicContentObject',
		'Get-PSFMessage',
		'Get-PSFLicense',
		'Get-PSFLocalizedString',
		'Get-PSFLoggingProvider',
		'Get-PSFMessageLevelModifier',
		'Get-PSFPipeline',
		'Get-PSFResultCache',
		'Get-PSFRunspace',
		'Get-PSFScriptblock',
		'Get-PSFTaskEngineCache',
		'Get-PSFTaskEngineTask',
		'Get-PSFTypeSerializationData',
		'Get-PSFUserChoice',
		'Import-PSFClixml',
		'Import-PSFCmdlet',
		'Import-PSFConfig',
		'Import-PSFLocalizedString',
		'Install-PSFLoggingProvider',
		'Invoke-PSFCommand',
		'Join-PSFPath',
		'New-PSFLicense',
		'New-PSFMessageLevelModifier',
		'New-PSFSessionContainer',
		'New-PSFSupportPackage',
		'Register-PSFConfig',
		'Register-PSFConfigSchema',
		'Register-PSFConfigValidation',
		'Register-PSFLoggingProvider',
		'Register-PSFMessageEvent',
		'Register-PSFMessageTransform',
		'Register-PSFParameterClassMapping',
		'Register-PSFRunspace',
		'Register-PSFSessionObjectType',
		'Register-PSFTaskEngineTask',
		'Register-PSFTeppArgumentCompleter',
		'Register-PSFTeppScriptblock',
		'Register-PSFTypeSerializationData',
		'Remove-PSFAlias',
		'Remove-PSFConfig',
		'Remove-PSFLicense',
		'Remove-PSFMessageLevelModifier',
		'Reset-PSFConfig',
		'Resolve-PSFDefaultParameterValue',
		'Resolve-PSFPath',
		'Select-PSFPropertyValue',
		'Set-PSFDynamicContentObject',
		'Set-PSFLoggingProvider',
		'Set-PSFResultCache',
		'Set-PSFScriptblock',
		'Set-PSFTaskEngineCache',
		'Set-PSFTeppResult',
		'Set-PSFTypeAlias',
		'Start-PSFRunspace',
		'Stop-PSFFunction',
		'Stop-PSFRunspace',
		'Test-PSFFunctionInterrupt',
		'Test-PSFParameterBinding',
		'Test-PSFPowerShell',
		'Test-PSFTaskEngineCache',
		'Test-PSFTaskEngineTask',
		'Unregister-PSFConfig',
		'Wait-PSFMessage',
		'Write-PSFHostColor',
		'Write-PSFMessageProxy'
	)
	
	# Cmdlets to export from this module
	CmdletsToExport		    = @(
		'Remove-PSFNull',
		'Select-PSFObject',
		'Set-PSFConfig',
		'Test-PSFShouldProcess',
		'Write-PSFMessage'
	)
	
	# Variables to export from this module
	VariablesToExport = ''
	
	# Aliases to export from this module
	AliasesToExport = @(
		'Get-LastResult',
		'glr',
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
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('scripting', 'infrastructure', 'logging', 'configuration')
			
			# A URL to the license for this module.
			LicenseUri = 'https://github.com/PowershellFrameworkCollective/psframework/blob/master/LICENSE.md'
			
			# A URL to the main website for this project.
			ProjectUri = 'http://psframework.org'
			
			# A URL to an icon representing this module.
			# IconUri = ''
			
			# ReleaseNotes of this module
			ReleaseNotes = 'https://github.com/PowershellFrameworkCollective/psframework/blob/master/PSFramework/changelog.md'
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}







