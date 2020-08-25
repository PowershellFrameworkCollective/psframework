# Load "Environment" variables within the module
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Environment", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\environment.ps1"

# Load Tab Expansion Plus Plus code (PS4 or older)
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  TEPP Core", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\teppCoreCode.ps1"