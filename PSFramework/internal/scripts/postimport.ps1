# Load the cmdlets
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Cmdlets", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\cmdlets.ps1"

# Import the aliases for PSFramework types
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  TypeAliases", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\bin\type-aliases.ps1"

# Load the strings
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Strings", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\strings.ps1"

# Initialize the configurations
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  ConfigurationSchemata", "")
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\configurationschemata\*.ps1"))
{
	[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("    $($file.FullName)", "")
	. Import-ModuleFile -Path $file.FullName
}
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  ConfigurationValidation", "")
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\configurationvalidation\*.ps1"))
{
	[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("    $($file.FullName)", "")
	. Import-ModuleFile -Path $file.FullName
}
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Configurations", "")
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\configurations\*.ps1"))
{
	[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("    $($file.FullName)", "")
	. Import-ModuleFile -Path $file.FullName
}

# Import configuration settings from registry
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  ConfigurationInitialization", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\loadConfigurationPersisted.ps1"

# Load each logging provider
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  LoggingProviders", "")
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\loggingProviders\*.ps1"))
{
	[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("    $($file.FullName)", "")
	. Import-ModuleFile -Path $file.FullName
}

# Start the logging system
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  LoggingInstanceCode", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\loggingProviderInstanceModuleCode.ps1"
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  LoggingRunspace", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\async-logging2.ps1"

# Launch the Tab Expansion system
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  TEPP Scripts", "")
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\tepp\scripts\*.ps1"))
{
	[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("    $($file.FullName)", "")
	. Import-ModuleFile -Path $file.FullName
}
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  TEPP Assignments", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\tepp\tepp-assignment.ps1"

# Load parameter class extensions
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Parameter Extension", "")
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\parameters\*.ps1"))
{
	[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("    $($file.FullName)", "")
	. Import-ModuleFile -Path $file.FullName
}

# Import the type extensions used for special types that need to be dynamically calculated
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Type Extension", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\bin\type-extensions.ps1"

# Register the task engine
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  TaskEngine Runspace", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\taskEngine.ps1"

# Register the unimport reaction
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Removal Event", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\removalEvent.ps1"

# Load special variables
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Variables", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\variables.ps1"

# Load Session Registrations for the Session Container feature
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Session Registration", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\sessionRegistration.ps1"

# Load resources for TEPP input completion
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Input TEPP Resources", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\teppInputResources.ps1"

# Load Scriptblocks
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Scriptblocks", "")
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\scriptblocks\*.ps1"))
{
	[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("    $($file.FullName)", "")
	. Import-ModuleFile -Path $file.FullName
}

# Finally register the license
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  License", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\license.ps1"