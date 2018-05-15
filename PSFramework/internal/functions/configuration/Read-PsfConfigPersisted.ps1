function Read-PsfConfigPersisted
{
<#
	.SYNOPSIS
		Reads configurations from persisted file / registry.
	
	.DESCRIPTION
		Reads configurations from persisted file / registry.
	
	.PARAMETER Scope
		Where to read from.
	
	.PARAMETER Module
		Load module specific data.
		Use this to load on-demand configuration only when the module is imported.
		Useful when using the config system as cache.
	
	.PARAMETER Hashtable
		Rather than returning results, insert them into this hashtable.
	
	.PARAMETER Default
		When inserting into a hashtable, existing values are overwritten by default.
		Enabling this setting will cause it to only insert values if the key does not exist yet.
#>
	[CmdletBinding()]
	Param (
		[PSFramework.Configuration.ConfigScope]
		$Scope,
		
		[string]
		$Module,
		
		[System.Collections.Hashtable]
		$Hashtable,
		
		[switch]
		$Default
	)
	
	begin
	{
		#region Helper Functions
		function New-ConfigItem
		{
			[CmdletBinding()]
			param (
				$FullName,
				
				$Value,
				
				$Type,
				
				[switch]
				$KeepPersisted,
				
				[switch]
				$Enforced
			)
			
			[pscustomobject]@{
				FullName  = $FullName
				Value	   = $Value
				Type	   = $Type
				KeepPersisted   = $KeepPersisted
				Enforced = $Enforced
			}
		}
		
		function Read-File
		{
			[CmdletBinding()]
			param (
				[string]
				$Path
			)
			
			if (-not (Test-Path $Path)) { return }
			
			$data = Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json
			foreach ($item in $data)
			{
				#region No Version
				if (-not $item.Version)
				{
					New-ConfigItem -FullName $item.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value, $item.Type))
				}
				#endregion No Version
				
				#region Version One
				if ($item.Version -eq 1)
				{
					if ($item.Style -eq "Simple") { New-ConfigItem -FullName $item.FullName -Value $item.Data }
					else
					{
						if ($item.Type -eq "Object")
						{
							New-ConfigItem -FullName $item.FullName -Value $item.Data -Type "Object" -KeepPersisted
						}
						else
						{
							New-ConfigItem -FullName $item.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value, $item.Type))
						}
					}
				}
				#endregion Version One
			}
		}
		
		function Read-Registry
		{
			[CmdletBinding()]
			param (
				$Path,
				
				[switch]
				$Enforced
			)
			
			if (-not (Test-Path $Path)) { return }
			
			$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
			
			foreach ($item in ((Get-ItemProperty -Path $Path -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
			{
				if ($item.Value -like "Object:*")
				{
					$data = $item.Value.Split(":", 2)
					New-ConfigItem -FullName $item.Name -Type $data[0] -Value $data[1] -KeepPersisted -Enforced:$Enforced
				}
				else
				{
					New-ConfigItem -FullName $item.Name -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value))
				}
			}
		}
		#endregion Helper Functions
		
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
		
		if (-not $Hashtable) { $results = @{ } }
		else { $results = $Hashtable }
		
		if ($Module) { $filename = "$($Module).xml" }
		else { $filename = "psf_config.xml" }
	}
	process
	{
		#region File - Computer Wide
		if ($Scope -band 64)
		{
			foreach ($item in (Read-File -Path (Join-Path $script:path_FileSystem $filename)))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		#endregion File - Computer Wide
		
		#region Registry - Computer Wide
		if ($Scope -band 4)
		{
			foreach ($item in (Read-Registry -Path $script:path_RegistryMachineDefault))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		#endregion Registry - Computer Wide
		
		#region File - User Shared
		if ($Scope -band 32)
		{
			foreach ($item in (Read-File -Path (Join-Path $script:path_FileUserShared $filename)))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		#endregion File - User Shared
		
		#region Registry - User Shared
		if ($Scope -band 1)
		{
			foreach ($item in (Read-Registry -Path $script:path_RegistryUserDefault))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		#endregion Registry - User Shared
		
		#region File - User Local
		if ($Scope -band 16)
		{
			foreach ($item in (Read-File -Path (Join-Path $script:path_FileUserLocal $filename)))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		#endregion File - User Local
		
		#region Registry - User Enforced
		if ($Scope -band 2)
		{
			foreach ($item in (Read-Registry -Path $script:path_RegistryUserEnforced -Enforced))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		#endregion Registry - User Enforced
		
		#region Registry - System Enforced
		if ($Scope -band 8)
		{
			foreach ($item in (Read-Registry -Path $script:path_RegistryMachineEnforced -Enforced))
			{
				if (-not $Default) { $results[$item.FullName] = $item }
				elseif (-not $results.ContainsKey($item.FullName)) { $results[$item.FullName] = $item }
			}
		}
		#endregion Registry - System Enforced
	}
	end
	{
		$results
	}
}