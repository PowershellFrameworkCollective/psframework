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
foreach ($file in (Get-ChildItem -Path "$PSModuleRoot\internal\tepp\scripts\"))
{
	. Import-ModuleFile -Path $file.FullName
}
. Import-ModuleFile -Path "$PSModuleRoot\internal\tepp\tepp-assignment.ps1"

# Load parameter class extensions
foreach ($file in (Get-ChildItem -Path "$PSModuleRoot\internal\parameters\" -Filter "*.ps1"))
{
	. Import-ModuleFile -Path $file.FullName
}

# Import the aliases for PSFramework types
. Import-ModuleFile -Path "$PSModuleRoot\bin\type-aliases.ps1"

# Register the task engine
. Import-ModuleFile -Path "$PSModuleRoot\internal\scripts\taskEngine.ps1"

# Register the unimport reaction
. Import-ModuleFile -Path "$PSModuleRoot\internal\scripts\removalEvent.ps1"

# Finally register the license
. Import-ModuleFile -Path "$PSModuleRoot\internal\scripts\license.ps1"

#region Declare runtime variable for the flow control component
$paramNewVariable = @{
	Name   = "psframework_killqueue"
	Value  = (New-Object PSFramework.Utility.LimitedConcurrentQueue[int](25))
	Option = 'ReadOnly'
	Scope  = 'Script'
	Description = 'Variable that is used to maintain the list of commands to kill. This is used by Test-PSFFunctionInterrupt. Note: The value tested is the hashcade from the callstack item.'
}

New-Variable @paramNewVariable
#endregion Declare runtime variable for the flow control component