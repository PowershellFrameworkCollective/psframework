# Registry not supported on not-windows
if (($PSVersionTable.PSVersion.Major -ge 6) -and ($PSVersionTable.OS -notlike "*Windows*"))
{
	return
}

if (-not [PSFramework.Configuration.ConfigurationHost]::ImportFromRegistryDone)
{
	$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'

	#region Import from registry
	$config_hash = @{ }
	foreach ($item in ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
	{
		try
		{
			$config_hash[$item.Name.ToLower()] = New-Object PSObject -Property @{
				Name	 = $item.Name
				Enforced = $false
				Value    = Convert-PsfConfigValue -Value $item.Value
			}
		}
		catch
		{
			Write-PSFMessage -Level Warning -Message "Failed to interpret configuration entry from registry: $($item.Name)" -ErrorRecord $_ -ModuleName PSFramework -FunctionName 'loadConfigurationFromRegistry.ps1'
		}
	}
	foreach ($item in ((Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
	{
		try
		{
			$config_hash[$item.Name.ToLower()] = New-Object PSObject -Property @{
				Name	 = $item.Name
				Enforced = $false
				Value    = Convert-PsfConfigValue -Value $item.Value
			}
		}
		catch
		{
			Write-PSFMessage -Level Warning -Message "Failed to interpret configuration entry from registry: $($item.Name)" -ErrorRecord $_ -ModuleName PSFramework -FunctionName 'loadConfigurationFromRegistry.ps1'
		}
	}
	foreach ($item in ((Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced" -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
	{
		try
		{
			$config_hash[$item.Name.ToLower()] = New-Object PSObject -Property @{
				Name	 = $item.Name
				Enforced = $true
				Value    = Convert-PsfConfigValue -Value $item.Value
			}
		}
		catch
		{
			Write-PSFMessage -Level Warning -Message "Failed to interpret configuration entry from registry: $($item.Name)" -ErrorRecord $_ -ModuleName PSFramework -FunctionName 'loadConfigurationFromRegistry.ps1'
		}
	}
	foreach ($item in ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced" -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
	{
		try
		{
			$config_hash[$item.Name.ToLower()] = New-Object PSObject -Property @{
				Name	 = $item.Name
				Enforced = $true
				Value    = Convert-PsfConfigValue -Value $item.Value
			}
		}
		catch
		{
			Write-PSFMessage -Level Warning -Message "Failed to interpret configuration entry from registry: $($item.Name)" -ErrorRecord $_ -ModuleName PSFramework -FunctionName 'loadConfigurationFromRegistry.ps1'
		}
	}
	#endregion Import from registry
	
	foreach ($value in $config_hash.Values)
	{
		try
		{
			Set-PSFConfig -Name $value.Name -Value $value.Value -EnableException
			[PSFramework.Configuration.ConfigurationHost]::Configurations[$value.Name.ToLower()].PolicySet = $true
			[PSFramework.Configuration.ConfigurationHost]::Configurations[$value.Name.ToLower()].PolicyEnforced = $value.Enforced
		}
		catch { }
	}
	
	[PSFramework.Configuration.ConfigurationHost]::ImportFromRegistryDone = $true
}
