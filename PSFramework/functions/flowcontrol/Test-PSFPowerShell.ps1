function Test-PSFPowerShell
{
<#
	.SYNOPSIS
		Tests for conditions in the PowerShell environment.
	
	.DESCRIPTION
		This helper command can evaluate various runtime conditions, such as:
		- PowerShell Version
		- PowerShell Edition
		- Operating System
		- Elevation
		This makes it easier to do conditional code.
		It also makes it easier to simulate code-paths during pester tests, by mocking this command.
	
	.PARAMETER PSMinVersion
		PowerShell must be running under at least this version.
	
	.PARAMETER PSMaxVersion
		PowerShell most not be runnign on a version higher than this.
	
	.PARAMETER Edition
		PowerShell must be running in the specifioed edition (Core or Desktop)
	
	.PARAMETER OperatingSystem
		PowerShell must be running on the specified OS.
	
	.PARAMETER Elevated
		PowerShell must be running with elevation.
		
		Note:
		This test is only supported on Windows.
		On other OS it will automatically succede and assume root privileges.
	
	.PARAMETER ComputerName
		The computer on which to test local PowerShell conditions.
		If this parameter is not specified, it tests the current PowerShell process and hosting OS.
		Accepts established PowerShell sessions.
	
	.PARAMETER Credential
		The credentials to use when connecting to a remote computer.
	
	.EXAMPLE
		PS C:\> Test-PSFPowerShell -PSMinVersion 5.0
	
		Will return $false, unless the executing powershell version is at least 5.0
	
	.EXAMPLE
		PS C:\> Test-PSFPowerShell -Edition Core
	
		Will return $true, if the current powershell session is a PowerShell core session.
	
	.EXAMPLE
		PS C:\> Test-PSFPowerShell -Elevated
	
		Will return $false if on windows and not running as admin.
		Will return $true otherwise.
	
	.EXAMPLE
		PS C:\> Test-PSFPowerShell -PSMinVersion 6.1 -OperatingSystem Windows
	
		Will return $false unless executed on a PowerShell 6.1 console running on windows.
#>
	[OutputType([System.Boolean])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFPowerShell')]
	param (
		[Version]
		$PSMinVersion,
		
		[Version]
		$PSMaxVersion,
		
		[PSFramework.FlowControl.PSEdition]
		$Edition,
		
		[PSFramework.FlowControl.OperatingSystem]
		[Alias('OS')]
		$OperatingSystem,
		
		[switch]
		$Elevated,
		
		[PSFComputer]
		$ComputerName,
		
		[PSCredential]
		$Credential
	)
	
	begin
	{
		$parameter = $PSBoundParameters | ConvertTo-PSFHashtable -Include ComputerName, Credential
	}
	process
	{
		#region Local execution for performance reasons separate
		if (-not $PSBoundParameters.ContainsKey('ComputerName'))
		{
			#region PS Version Test
			if ($PSMinVersion -and ($PSMinVersion -ge $PSVersionTable.PSVersion))
			{
				return $false
			}
			if ($PSMaxVersion -and ($PSMaxVersion -le $PSVersionTable.PSVersion))
			{
				return $false
			}
			#endregion PS Version Test
			
			#region PS Edition Test
			if ($Edition -like "Desktop")
			{
				if ($PSVersionTable.PSEdition -eq "Core")
				{
					return $false
				}
			}
			if ($Edition -like "Core")
			{
				if ($PSVersionTable.PSEdition -ne "Core")
				{
					return $false
				}
			}
			#endregion PS Edition Test
			
			#region OS Test
			if ($OperatingSystem)
			{
				switch ($OperatingSystem)
				{
					"MacOS"
					{
						if ($PSVersionTable.PSVersion.Major -lt 6) { return $false }
						if (-not $IsMacOS) { return $false }
					}
					"Linux"
					{
						if ($PSVersionTable.PSVersion.Major -lt 6) { return $false }
						if (-not $IsLinux) { return $false }
					}
					"Windows"
					{
						if (($PSVersionTable.PSVersion.Major -ge 6) -and (-not $IsWindows))
						{
							return $false
						}
					}
				}
			}
			#endregion OS Test
			
			#region Elevation
			if ($Elevated)
			{
				if (($PSVersionTable.PSVersion.Major -lt 6) -or ($IsWindows))
				{
					$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
					$principal = New-Object Security.Principal.WindowsPrincipal $identity
					if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
					{
						return $false
					}
				}
			}
			#endregion Elevation
			
			return $true
		}
		#endregion Local execution for performance reasons separate
		
		Invoke-PSFCommand @parameter -ScriptBlock {
			#region PS Version Test
			if ($PSMinVersion -and ($PSMinVersion -ge $PSVersionTable.PSVersion))
			{
				return $false
			}
			if ($PSMaxVersion -and ($PSMaxVersion -le $PSVersionTable.PSVersion))
			{
				return $false
			}
			#endregion PS Version Test
			
			#region PS Edition Test
			if ($Edition -like "Desktop")
			{
				if ($PSVersionTable.PSEdition -eq "Core")
				{
					return $false
				}
			}
			if ($Edition -like "Core")
			{
				if ($PSVersionTable.PSEdition -ne "Core")
				{
					return $false
				}
			}
			#endregion PS Edition Test
			
			#region OS Test
			if ($OperatingSystem)
			{
				switch ($OperatingSystem)
				{
					"MacOS"
					{
						if ($PSVersionTable.PSVersion.Major -lt 6) { return $false }
						if (-not $IsMacOS) { return $false }
					}
					"Linux"
					{
						if ($PSVersionTable.PSVersion.Major -lt 6) { return $false }
						if (-not $IsLinux) { return $false }
					}
					"Windows"
					{
						if (($PSVersionTable.PSVersion.Major -ge 6) -and (-not $IsWindows))
						{
							return $false
						}
					}
				}
			}
			#endregion OS Test
			
			#region Elevation
			if ($Elevated)
			{
				if (($PSVersionTable.PSVersion.Major -lt 6) -or ($IsWindows))
				{
					$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
					$principal = New-Object Security.Principal.WindowsPrincipal $identity
					if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))
					{
						return $false
					}
				}
			}
			#endregion Elevation
			
			return $true
		}
	}
}