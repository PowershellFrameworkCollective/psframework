$moduleRoot = Split-Path (Split-Path $PSScriptRoot)

# Load the cmdlets
"$($moduleRoot)\internal\scripts\cmdlets.ps1"

# Import the aliases for PSFramework types
"$($moduleRoot)\bin\type-aliases.ps1"

# Load the strings
"$($moduleRoot)\internal\scripts\strings.ps1"

# Initialize the configurations
foreach ($file in (Get-ChildItem -Path "$($moduleRoot)\internal\configurationschemata\*.ps1"))
{
	$file.FullName
}
foreach ($file in (Get-ChildItem -Path "$($moduleRoot)\internal\configurationvalidation\*.ps1"))
{
	$file.FullName
}
foreach ($file in (Get-ChildItem -Path "$($moduleRoot)\internal\configurations\*.ps1"))
{
	$file.FullName
}

# Import configuration settings from registry
"$($moduleRoot)\internal\scripts\loadConfigurationPersisted.ps1"

# Load each logging provider
foreach ($file in (Get-ChildItem -Path "$($moduleRoot)\internal\loggingProviders\*.ps1"))
{
	$file.FullName
}

# Start the logging system
"$($moduleRoot)\internal\scripts\loggingProviderInstanceModuleCode.ps1"
"$($moduleRoot)\internal\scripts\async-logging2.ps1"

# Launch the Tab Expansion system
foreach ($file in (Get-ChildItem -Path "$($moduleRoot)\internal\tepp\scripts\*.ps1"))
{
	$file.FullName
}
"$($moduleRoot)\internal\tepp\tepp-assignment.ps1"

# Load parameter class extensions
foreach ($file in (Get-ChildItem -Path "$($moduleRoot)\internal\parameters\*.ps1"))
{
	$file.FullName
}

# Import the type extensions used for special types that need to be dynamically calculated
"$($moduleRoot)\bin\type-extensions.ps1"

# Register the task engine
"$($moduleRoot)\internal\scripts\taskEngine.ps1"

# Register the unimport reaction
"$($moduleRoot)\internal\scripts\removalEvent.ps1"

# Load special variables
"$($moduleRoot)\internal\scripts\variables.ps1"

# Load Session Registrations for the Session Container feature
"$($moduleRoot)\internal\scripts\sessionRegistration.ps1"

# Load resources for TEPP input completion
"$($moduleRoot)\internal\scripts\teppInputResources.ps1"

# Load Scriptblocks
foreach ($file in (Get-ChildItem -Path "$($moduleRoot)\internal\scriptblocks\*.ps1"))
{
	$file.FullName
}

# Load Filters
foreach ($file in (Get-ChildItem -Path "$($moduleRoot)\internal\filter\*.ps1")) {
	$file.FullName
}

# Finally register the license
"$($moduleRoot)\internal\scripts\license.ps1"