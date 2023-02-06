$moduleRoot = Split-Path (Split-Path $PSScriptRoot)

# Load Assembly
"$($moduleRoot)\bin\assembly.ps1"

# Load "Environment" variables within the module
"$($moduleRoot)\internal\scripts\environment.ps1"

# Load Tab Expansion Plus Plus code (PS4 or older)
"$($moduleRoot)\internal\scripts\teppCoreCode.ps1"

# Load resources for TEPP input completion
"$($moduleRoot)\internal\scripts\teppSimpleCompleter.ps1"