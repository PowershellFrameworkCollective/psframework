# Load "Environment" variables within the module
. Import-ModuleFile -Path "$($PSModuleRoot)$($dc)internal$($dc)scripts$($dc)environment.ps1"

if (-not ([PSFramework.Message.LogHost]::LoggingPath)) { [PSFramework.Message.LogHost]::LoggingPath = $script:path_Logging }