# Initialize the configurations
foreach ($file in (Get-ChildItem -Path "$PSModuleRoot\internal\configurationvalidation\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}
foreach ($file in (Get-ChildItem -Path "$PSModuleRoot\internal\configurations\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}

# Import configuration settings from registry
. Import-ModuleFile -Path "$PSModuleRoot\internal\scripts\loadConfigurationFromRegistry.ps1"

# Load each logging provider
foreach ($file in (Get-ChildItem -Path "$PSModuleRoot\internal\loggingProviders\"))
{
	. Import-ModuleFile -Path $file.FullName
}

# Start the logging system
. Import-ModuleFile -Path "$PSModuleRoot\internal\scripts\async-logging2.ps1"

# Launch the Tab Expansion system
foreach ($file in (Get-ChildItem -Path "$PSModuleRoot\internal\tepp\\scripts"))
{
	. Import-ModuleFile -Path $file.FullName
}
. Import-ModuleFile -Path "$PSModuleRoot\internal\tepp\tepp-assignment.ps1"

# Register the task engine
. Import-ModuleFile -Path "$PSModuleRoot\internal\scripts\taskEngine.ps1"

# Finally register the license
. Import-ModuleFile -Path "$PSModuleRoot\internal\scripts\license.ps1"