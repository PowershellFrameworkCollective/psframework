function Register-PSFConfig {
	<#
	.SYNOPSIS
		Registers an existing configuration object in registry.
	
	.DESCRIPTION
		Registers an existing configuration object in registry.
		This allows simple persisting of settings across powershell consoles.
		It also can be used to generate a registry template, which can then be used to create policies.
	
	.PARAMETER Config
		The configuration object to write to registry.
		Can be retrieved using Get-PSFConfig.
	
	.PARAMETER FullName
		The full name of the setting to be written to registry.
	
	.PARAMETER Module
		The name of the module, whose settings should be written to registry.
	
	.PARAMETER Name
		Default: "*"
		Used in conjunction with the -Module parameter to restrict the number of configuration items written to registry.
	
	.PARAMETER Scope
		Default: UserDefault
		Who will be affected by this export how? Current user or all? Default setting or enforced?
		For more information on scopes and what location they correspond to, see:
		https://psframework.org/documentation/documents/psframework/configuration/persistence-location.html

		Environment variable scopes will only be persisted to the current process, affecting all child processes but not the computer in its entirety.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Get-PSFConfig psframework.message.* | Register-PSFConfig
	
		Retrieves all configuration items that that start with psframework.message. and registers them in registry for the current user.
	
	.EXAMPLE
		PS C:\> Register-PSFConfig -FullName "psframework.developer.mode.enable" -Scope SystemDefault
	
		Retrieves the configuration item "psframework.developer.mode.enable" and registers it in registry as the default setting for all users on this machine.
	
	.EXAMPLE
		PS C:\> Register-PSFConfig -Module MyModule -Scope SystemMandatory
	
		Retrieves all configuration items of the module MyModule, then registers them in registry to enforce them for all users on the current system.
#>
	[CmdletBinding(DefaultParameterSetName = "Default", HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFConfig')]
	param (
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipeline = $true)]
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipeline = $true)]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Name", Position = 0)]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = "Name", Position = 1)]
		[string]
		$Name = "*",
		
		[PSFramework.Configuration.ConfigScope]
		$Scope = "UserDefault",
		
		[switch]
		$EnableException
	)
	
	begin {
		if ($script:NoRegistry -and ($Scope -band 10)) {
			Stop-PSFFunction -String 'Register-PSFConfig.NoRegistry' -Tag 'NotSupported' -Category ResourceUnavailable
			return
		}
		
		# Linux and MAC default to local user store file
		if ($script:NoRegistry -and ($Scope -eq "UserDefault")) {
			$Scope = [PSFramework.Configuration.ConfigScope]::FileUserLocal
		}
		# Linux and MAC get redirection for SystemDefault to FileSystem
		if ($script:NoRegistry -and ($Scope -eq "SystemDefault")) {
			$Scope = [PSFramework.Configuration.ConfigScope]::FileSystem
		}
		
		#region Functions
		function Resolve-ConfigItem {
			[OutputType([PSFramework.Configuration.Config[]])]
			[CmdletBinding()]
			param (
				[AllowEmptyCollection()]
				[AllowNull()]
				[PSFramework.Configuration.Config[]]
				$Config,
		
				[AllowEmptyCollection()]
				[AllowNull()]
				[string[]]
				$FullName,
		
				[AllowEmptyString()]
				[AllowNull()]
				[string]
				$Module,
		
				[AllowEmptyString()]
				[AllowNull()]
				[string]
				$Name
			)

			$names = [System.Collections.ArrayList]@()

			if ($Config) {
				$Config
				$null = $names.AddRange(@($Config.FullName))
			}
			if ($FullName) {
				foreach ($item in [PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object FullName -In $FullName) {
					if ($item.FullName -in $names) { continue }
					$item
					$null = $names.Add($item.FullName)
				}
			}
			if ($Module) {
				foreach ($item in [PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object Module -EQ $Module | Where-Object Name -Like $Name) {
					if ($item.FullName -in $names) { continue }
					$item
					$null = $names.Add($item.FullName)
				}
			}
		}

		function Write-Config {
			[CmdletBinding()]
			param (
				[PSFramework.Configuration.Config]
				$Config,
				
				[PSFramework.Configuration.ConfigScope]
				$Scope,
				
				[bool]
				$EnableException,
				
				[string]
				$FunctionName = (Get-PSCallStack)[0].Command
			)
			
			if (-not $Config -or ($Config.RegistryData -eq "<type not supported>")) {
				Stop-PSFFunction -String 'Register-PSFConfig.Type.NotSupported' -StringValues $Config.FullName -EnableException $EnableException -Category InvalidArgument -Tag "config", "fail" -Target $Config -FunctionName $FunctionName -ModuleName "PSFramework"
				return
			}
			
			try {
				Write-PSFMessage -Level Verbose -String 'Register-PSFConfig.Registering' -StringValues $Config.FullName, $Scope -Tag "Config" -Target $Config -FunctionName $FunctionName -ModuleName "PSFramework"
				#region User Default
				if (1 -band $Scope) {
					Ensure-RegistryPath -Path $script:path_RegistryUserDefault -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryUserDefault -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				#endregion User Default
				
				#region User Mandatory
				if (2 -band $Scope) {
					Ensure-RegistryPath -Path $script:path_RegistryUserEnforced -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryUserEnforced -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				#endregion User Mandatory
				
				#region System Default
				if (4 -band $Scope) {
					Ensure-RegistryPath -Path $script:path_RegistryMachineDefault -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryMachineDefault -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				#endregion System Default
				
				#region System Mandatory
				if (8 -band $Scope) {
					Ensure-RegistryPath -Path $script:path_RegistryMachineEnforced -ErrorAction Stop
					Set-ItemProperty -Path $script:path_RegistryMachineEnforced -Name $Config.FullName -Value $Config.RegistryData -ErrorAction Stop
				}
				#endregion System Mandatory
			}
			catch {
				Stop-PSFFunction -String 'Register-PSFConfig.Registering.Failed' -StringValues $Config.FullName, $Scope -EnableException $EnableException -Tag "config", "fail" -Target $Config -ErrorRecord $_ -FunctionName $FunctionName -ModuleName "PSFramework"
				return
			}
		}
		
		function Write-Environment {
			[CmdletBinding()]
			param (
				[PSFramework.Configuration.Config]
				$Config,
				
				[PSFramework.Configuration.ConfigScope]
				$Scope
			)

			if ($Scope -band 128) {
				Set-Item -Path "env:\PSFramework_$($Config.FullName)" -Value $Config.RegistryData
			}
			if ($Scope -band 256) {
				Set-Item -Path "env:\PSF_$($Config.FullName)" -Value $Config.RegistryData
			}
		}

		function Ensure-RegistryPath {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
			[CmdletBinding()]
			param (
				[string]
				$Path
			)
			
			if (-not (Test-Path $Path)) {
				$null = New-Item $Path -Force
			}
		}
		#endregion Functions

		# For file based persistence
		$fileConfigurationItems = @()
	}
	process {
		if (Test-PSFFunctionInterrupt) { return }

		$configItems = Resolve-ConfigItem -Config $Config -FullName $FullName -Module $Module -Name $Name
		
		#region Registry Based
		if ($Scope -band 15) {
			foreach ($item in $configItems) {
				Write-Config -Config $item -Scope $Scope -EnableException $EnableException
			}
		}
		#endregion Registry Based
		
		#region File Based
		if ($Scope -band 112) {
			foreach ($item in $configItems) {
				if ($fileConfigurationItems.FullName -notcontains $item.FullName) { $fileConfigurationItems += $item }
			}
		}
		#endregion File Based

		#region Environment Based
		if ($Scope -band 384) {
			foreach ($item in $configItems) {
				Write-Environment -Config $item -Scope $Scope
			}
		}
		#endregion Environment Based
	}
	end {
		#region Finish File Based Persistence
		if ($Scope -band 16) {
			Write-PsfConfigFile -Config $fileConfigurationItems -Path (Join-Path $script:path_FileUserLocal "psf_config.json")
		}
		if ($Scope -band 32) {
			Write-PsfConfigFile -Config $fileConfigurationItems -Path (Join-Path $script:path_FileUserShared "psf_config.json")
		}
		if ($Scope -band 64) {
			Write-PsfConfigFile -Config $fileConfigurationItems -Path (Join-Path $script:path_FileSystem "psf_config.json")
		}
		#endregion Finish File Based Persistence
	}
}