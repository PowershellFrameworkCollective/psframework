# Initialize the configurations
foreach ($file in (Get-ChildItem -Path "$PSFrameworkModuleRoot\internal\configurationvalidation\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}
foreach ($file in (Get-ChildItem -Path "$PSFrameworkModuleRoot\internal\configurations\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}

# Import configuration settings from registry
. Import-ModuleFile -Path "$PSFrameworkModuleRoot\internal\scripts\loadConfigurationFromRegistry.ps1"

# Load each logging provider
foreach ($file in (Get-ChildItem -Path "$PSFrameworkModuleRoot\internal\loggingProviders\"))
{
	. Import-ModuleFile -Path $file.FullName
}

# Start the logging system
. Import-ModuleFile -Path "$PSFrameworkModuleRoot\internal\scripts\async-logging2.ps1"

# Launch the Tab Expansion system
foreach ($file in (Get-ChildItem -Path "$PSFrameworkModuleRoot\internal\tepp\\scripts"))
{
	. Import-ModuleFile -Path $file.FullName
}
. Import-ModuleFile -Path "$PSFrameworkModuleRoot\internal\tepp\tepp-assignment.ps1"