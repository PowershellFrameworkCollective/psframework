# Load "Environment" variables within the module
[PSFramework.PSFCore.PSFCoreHost]::WriteDebug("  Environment", "")
. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\environment.ps1"