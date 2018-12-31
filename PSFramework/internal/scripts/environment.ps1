#region Paths
$script:path_RegistryUserDefault = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default"
$script:path_RegistryUserEnforced = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced"
$script:path_RegistryMachineDefault = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default"
$script:path_RegistryMachineEnforced = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced"
$psVersionName = "WindowsPowerShell"
if ($PSVersionTable.PSVersion.Major -ge 6) { $psVersionName = "PowerShell" }

#region User Local
if ($IsLinux -or $IsMacOs)
{
	# Defaults to $Env:XDG_CONFIG_HOME on Linux or MacOS ($HOME/.config/)
	$fileUserLocal = $Env:XDG_CONFIG_HOME
	if (-not $fileUserLocal) { $fileUserLocal = Join-Path $HOME .config/ }
	
	$script:path_FileUserLocal = Join-Path (Join-Path $fileUserLocal $psVersionName) "PSFramework/"
}
else
{
	# Defaults to $Env:LocalAppData on Windows
	$script:path_FileUserLocal = Join-Path $Env:LocalAppData "$psVersionName\PSFramework\Config"
	if (-not $script:path_FileUserLocal) { $script:path_FileUserLocal = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "$psVersionName\PSFramework\Config" }
}
#endregion User Local

#region User Shared
if ($IsLinux -or $IsMacOs)
{
	# Defaults to the first value in $Env:XDG_CONFIG_DIRS on Linux or MacOS (or $HOME/.local/share/)
	$fileUserShared = @($Env:XDG_CONFIG_DIRS -split ([IO.Path]::PathSeparator))[0]
	if (-not $fileUserShared) { $fileUserShared = Join-Path $HOME .local/share/ }
	
	$script:path_FileUserShared = Join-Path (Join-Path $fileUserShared $psVersionName) "PSFramework/"
}
else
{
	# Defaults to $Env:AppData on Windows
	$script:path_FileUserShared = Join-Path $Env:AppData "$psVersionName\PSFramework\Config"
	if (-not $Env:AppData) { $script:path_FileUserShared = Join-Path ([Environment]::GetFolderPath("ApplicationData")) "$psVersionName\PSFramework\Config" }
}
#endregion User Shared

#region System
if ($IsLinux -or $IsMacOs)
{
	# Defaults to /etc/xdg elsewhere
	$XdgConfigDirs = $Env:XDG_CONFIG_DIRS -split ([IO.Path]::PathSeparator) | Where-Object { $_ -and (Test-Path $_) }
	if ($XdgConfigDirs.Count -gt 1) { $basePath = $XdgConfigDirs[1] }
	else { $basePath = "/etc/xdg/" }
	$script:path_FileSystem = Join-Path $basePath "$psVersionName/PSFramework/"
}
else
{
	# Defaults to $Env:ProgramData on Windows
	$script:path_FileSystem = Join-Path $Env:ProgramData "$psVersionName\PSFramework\Config"
	if (-not $script:path_FileSystem) { $script:path_FileSystem = Join-Path ([Environment]::GetFolderPath("CommonApplicationData")) "$psVersionName\PSFramework\Config" }
}
#endregion System

#region Special Paths
if ($IsLinux -or $IsMacOs)
{
	$script:path_Logging = Join-Path (Split-Path $script:path_FileUserShared) "Logs/"
	$script:path_typedata = Join-Path $script:path_FileUserShared "TypeData/"
}
else
{
	# Defaults to $Env:AppData on Windows
	$script:path_Logging = Join-Path $Env:AppData "$psVersionName\PSFramework\Logs"
	$script:path_typedata = Join-Path $Env:AppData "$psVersionName\PSFramework\TypeData"
	if (-not $Env:AppData)
	{
		$script:path_Logging = Join-Path ([Environment]::GetFolderPath("ApplicationData")) "$psVersionName\PSFramework\Logs"
		$script:path_typedata = Join-Path ([Environment]::GetFolderPath("ApplicationData")) "$psVersionName\PSFramework\TypeData"
	}
}

#endregion Special Paths
#endregion Paths

# Determine Registry Availability
$script:NoRegistry = $false
if (($PSVersionTable.PSVersion.Major -ge 6) -and ($PSVersionTable.OS -notlike "*Windows*"))
{
	$script:NoRegistry = $true
}

if (-not ([PSFramework.Message.LogHost]::LoggingPath)) { [PSFramework.Message.LogHost]::LoggingPath = $script:path_Logging }

[PSFramework.PSFCore.PSFCoreHost]::ModuleRoot = $script:ModuleRoot
# Run the library initialization logic
# Needed before the configuration system loads
[PSFramework.PSFCore.PSFCoreHost]::Initialize()