#region Paths
$script:path_RegistryUserDefault = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default"
$script:path_RegistryUserEnforced = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced"
$script:path_RegistryMachineDefault = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default"
$script:path_RegistryMachineEnforced = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced"
$psVersionName = "WindowsPowerShell"
if ($PSVersionTable.PSVersion.Major -ge 6) { $psVersionName = "PowerShell" }

if (-not $script:path_FileUserLocal)
{
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
}
if (-not $script:path_FileUserShared)
{
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
		if (-not $script:path_FileUserShared) { $script:path_FileUserShared = Join-Path ([Environment]::GetFolderPath("ApplicationData")) "$psVersionName\PSFramework\Config" }
	}
}
if (-not $script:path_FileSystem)
{
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
}
#endregion Paths

# Determine Registry Availability
$script:NoRegistry = $false
if (($PSVersionTable.PSVersion.Major -ge 6) -and ($PSVersionTable.OS -notlike "*Windows*"))
{
	$script:NoRegistry = $true
}

if (-not [PSFramework.Configuration.ConfigurationHost]::ImportFromRegistryDone)
{
	# Read config from all settings
	$config_hash = Read-PsfConfigPersisted -Scope 127
	
	foreach ($value in $config_hash.Values)
	{
		try
		{
			if (-not $value.KeepPersisted) { Set-PSFConfig -FullName $value.FullName -Value $value.Value -EnableException }
			else { Set-PSFConfig -FullName $value.FullName -PersistedValue $value.Value -PersistedType $value.Type -EnableException }
			[PSFramework.Configuration.ConfigurationHost]::Configurations[$value.Name.ToLower()].PolicySet = $value.Policy
			[PSFramework.Configuration.ConfigurationHost]::Configurations[$value.Name.ToLower()].PolicyEnforced = $value.Enforced
		}
		catch { }
	}
	
	[PSFramework.Configuration.ConfigurationHost]::ImportFromRegistryDone = $true
}
