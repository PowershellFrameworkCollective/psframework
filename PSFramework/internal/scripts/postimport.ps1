# Load the cmdlets
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\cmdlets.ps1"

# Import the aliases for PSFramework types
. Import-ModuleFile -Path "$($script:ModuleRoot)\bin\type-aliases.ps1"

# Load the strings
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\strings.ps1"

# Initialize the configurations
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\configurationschemata\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\configurationvalidation\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\configurations\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}

# Import configuration settings from registry
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\loadConfigurationPersisted.ps1"

# Load each logging provider
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\loggingProviders\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}

# Start the logging system
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\async-logging2.ps1"

# Launch the Tab Expansion system
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\tepp\scripts\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\tepp\tepp-assignment.ps1"

# Load parameter class extensions
foreach ($file in (Get-ChildItem -Path "$($script:ModuleRoot)\internal\parameters\*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}

# Import the type extensions used for special types that need to be dynamically calculated
. Import-ModuleFile -Path "$($script:ModuleRoot)\bin\type-extensions.ps1"

# Register the task engine
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\taskEngine.ps1"

# Register the unimport reaction
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\removalEvent.ps1"

# Load special variables
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\variables.ps1"

# Load Session Registrations for the Session Container feature
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\sessionRegistration.ps1"

# Load resources for TEPP input completion
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\teppInputResources.ps1"

# Finally register the license
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\license.ps1"