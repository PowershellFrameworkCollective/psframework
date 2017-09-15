if (-not [PSFramework.Configuration.ConfigurationHost]::ImportFromRegistryDone)
{
	$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'

	function Convert-RegType
	{
		[CmdletBinding()]
		Param (
			[string]
			$Value
		)
		
		$index = $Value.IndexOf(":")
		if ($index -lt 1) { throw "No type identifier found!" }
		$type = $Value.Substring(0, $index).ToLower()
		$content = $Value.Substring($index + 1)
		
		switch ($type)
		{
			"bool"
			{
				if ($content -eq "true") { return $true }
				if ($content -eq "1") { return $true }
				if ($content -eq "false") { return $false }
				if ($content -eq "0") { return $false }
				throw "Failed to interpret as bool: $content"
			}
			"int" { return ([int]$content) }
			"double" { return [double]$content }
			"long" { return [long]$content }
			"string" { return $content }
			"timespan" { return (New-Object System.TimeSpan($content)) }
			"datetime" { return (New-Object System.DateTime($content)) }
			"consolecolor" { return ([System.ConsoleColor]$content)}
			
			default { throw "Unknown type identifier" }
		}
	}

	#region Import from registry
	$config_hash = @{ }
	foreach ($item in ((Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
	{
		try
		{
			$config_hash[$item.Name.ToLower()] = New-Object PSObject -Property @{
				Name	 = $item.Name
				Enforced = $false
				Value    = Convert-RegType -Value $item.Value
			}
		}
		catch
		{
			Write-PSFMessage -Level Warning -Message "Failed to interpret configuration entry from registry: $($item.Name)" -ErrorRecord $_
		}
	}
	foreach ($item in ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
	{
		try
		{
			$config_hash[$item.Name.ToLower()] = New-Object PSObject -Property @{
				Name	 = $item.Name
				Enforced = $false
				Value    = Convert-RegType -Value $item.Value
			}
		}
		catch
		{
			Write-PSFMessage -Level Warning -Message "Failed to interpret configuration entry from registry: $($item.Name)" -ErrorRecord $_
		}
	}
	foreach ($item in ((Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced" -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
	{
		try
		{
			$config_hash[$item.Name.ToLower()] = New-Object PSObject -Property @{
				Name	 = $item.Name
				Enforced = $true
				Value    = Convert-RegType -Value $item.Value
			}
		}
		catch
		{
			Write-PSFMessage -Level Warning -Message "Failed to interpret configuration entry from registry: $($item.Name)" -ErrorRecord $_
		}
	}
	foreach ($item in ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced" -ErrorAction Ignore).PSObject.Properties | Where-Object Name -NotIn $common))
	{
		try
		{
			$config_hash[$item.Name.ToLower()] = New-Object PSObject -Property @{
				Name	 = $item.Name
				Enforced = $true
				Value    = Convert-RegType -Value $item.Value
			}
		}
		catch
		{
			Write-PSFMessage -Level Warning -Message "Failed to interpret configuration entry from registry: $($item.Name)" -ErrorRecord $_
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
