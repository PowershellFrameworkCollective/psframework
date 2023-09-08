function Unregister-PSFConfig {
	<#
	.SYNOPSIS
		Removes registered configuration settings.
	
	.DESCRIPTION
		Removes registered configuration settings.
		This function can be used to remove settings that have been persisted for either user or computer.
		It can also remove persisted settings provided via Environment variable, but only for the current process (so new child-processes will no longer inherit them)
	
		Note: This command has no effect on configuration settings currently in memory.
	
	.PARAMETER ConfigurationItem
		A configuration object as returned by Get-PSFConfig.

	.PARAMETER PersistedItem
		A configuration object as returned by Get-PSFConfig -Persisted.
		Objects provided this way ignore the Scope parameter - they are unregistered from where they were found.
	
	.PARAMETER FullName
		The full name of the configuration setting to purge.
	
	.PARAMETER Module
		The module, amongst which settings should be unregistered.
	
	.PARAMETER Name
		The name of the setting to unregister.
		For use together with the module parameter, to limit the amount of settings that are unregistered.
	
	.PARAMETER Scope
		Settings can be set to either default or enforced, for user or the entire computer.
		They can also be persisted via files under appdata, localappdata or programmdata.
		https://psframework.org/documentation/documents/psframework/configuration/persistence-location.html

		By default, only DefaultSettings for the user are unregistered.
		Use this parameter to choose the actual scope for the command to process.
	
	.EXAMPLE
		PS C:\> Get-PSFConfig | Unregister-PSFConfig
	
		Completely removes all registered configurations currently loaded in memory.
		In most cases, this will mean removing all registered configurations.
	
	.EXAMPLE
		PS C:\> Unregister-PSFConfig -Scope SystemDefault -FullName 'MyModule.Path.DefaultExport'
	
		Unregisters the setting 'MyModule.Path.DefaultExport' from the list of computer-wide defaults.
		Note: Changing system wide settings requires running the console with elevation.
	
	.EXAMPLE
		PS C:\> Unregister-PSFConfig -Module MyModule
	
		Unregisters all configuration settings for the module MyModule.
#>
	[CmdletBinding(DefaultParameterSetName = 'Pipeline', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Unregister-PSFConfig')]
	param (
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[PSFramework.Configuration.Config[]]
		$ConfigurationItem,

		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[PSFramework.Configuration.PersistedConfig[]]
		$PersistedItem,
		
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Module')]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = 'Module')]
		[string]
		$Name = "*",
		
		[PSFramework.Configuration.ConfigScope]
		$Scope = "UserDefault"
	)
	
	begin {
		#region Functions
		function Remove-PersistedConfig {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$FullName,

				[PSFramework.Configuration.ConfigScope]
				$Scope,

				[hashtable]
				$FileConfig
			)

			if ($Scope -band [PSFramework.Configuration.ConfigScope]::UserDefault) {
				Remove-ItemProperty -Path $script:path_RegistryUserDefault -Name $FullName -ErrorAction SilentlyContinue
			}
			if ($Scope -band [PSFramework.Configuration.ConfigScope]::UserMandatory) {
				Remove-ItemProperty -Path $script:path_RegistryUserEnforced -Name $FullName -ErrorAction SilentlyContinue
			}
			if ($Scope -band [PSFramework.Configuration.ConfigScope]::SystemDefault) {
				Remove-ItemProperty -Path $script:path_RegistryMachineDefault -Name $FullName -ErrorAction SilentlyContinue
			}
			if ($Scope -band [PSFramework.Configuration.ConfigScope]::SystemMandatory) {
				Remove-ItemProperty -Path $script:path_RegistryMachineEnforced -Name $FullName -ErrorAction SilentlyContinue
			}

			if ($Scope -band [PSFramework.Configuration.ConfigScope]::FileUserLocal -and $FileConfig['FileUserLocal']) {
				$toRemove = @()
				$toRemove = $FileConfig['FileUserLocal'].Properties | Where-Object FullName -Like $FullName
				if ($toRemove) {
					$FileConfig['FileUserLocal'].Properties = $FileConfig['FileUserLocal'].Properties | Where-Object FullName -NotIn $toRemove.FullName
					$FileConfig['FileUserLocal'].Changed = $true
				}
			}
			if ($Scope -band [PSFramework.Configuration.ConfigScope]::FileUserShared -and $FileConfig['FileUserShared']) {
				$toRemove = @()
				$toRemove = $FileConfig['FileUserShared'].Properties | Where-Object FullName -Like $FullName
				if ($toRemove) {
					$FileConfig['FileUserShared'].Properties = $FileConfig['FileUserShared'].Properties | Where-Object FullName -NotIn $toRemove.FullName
					$FileConfig['FileUserShared'].Changed = $true
				}
			}
			if ($Scope -band [PSFramework.Configuration.ConfigScope]::FileSystem -and $FileConfig['FileSystem']) {
				$toRemove = @()
				$toRemove = $FileConfig['FileSystem'].Properties | Where-Object FullName -Like $FullName
				if ($toRemove) {
					$FileConfig['FileSystem'].Properties = $FileConfig['FileSystem'].Properties | Where-Object FullName -NotIn $toRemove.FullName
					$FileConfig['FileSystem'].Changed = $true
				}
			}

			# Environment Variables can only be unregistered from current process, so child-consoles don't see it
			if ($Scope -band [PSFramework.Configuration.ConfigScope]::Environment) {
				Remove-Item -Path "env:\PSFramework_$FullName" -ErrorAction Ignore
			}
			if ($Scope -band [PSFramework.Configuration.ConfigScope]::EnvironmentSimple) {
				Remove-Item -Path "env:\PSF_$FullName" -ErrorAction Ignore
			}
		}
		#endregion Functions

		if ($script:NoRegistry -and ($Scope -band 10)) {
			Stop-PSFFunction -String 'Unregister-PSFConfig.NoRegistry' -Tag 'NotSupported' -Category ResourceUnavailable
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
		
		#region Initialize Collection
		$pathProperties = @{}
		$fileUserLocalSettings = @()
		if (Test-Path (Join-Path $script:path_FileUserLocal "psf_config.json")) { $fileUserLocalSettings = Get-Content (Join-Path $script:path_FileUserLocal "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
		if ($fileUserLocalSettings) {
			$pathProperties['FileUserLocal'] = [pscustomobject]@{
				Path       = (Join-Path $script:path_FileUserLocal "psf_config.json")
				Properties = $fileUserLocalSettings
				Changed    = $false
				Scope      = 'FileUserLocal'
			}
		}

		$fileUserSharedSettings = @()
		if (Test-Path (Join-Path $script:path_FileUserShared "psf_config.json")) { $fileUserSharedSettings = Get-Content (Join-Path $script:path_FileUserShared "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
		if ($fileUserSharedSettings) {
			$pathProperties['FileUserShared'] = [pscustomobject]@{
				Path       = (Join-Path $script:path_FileUserShared "psf_config.json")
				Properties = $fileUserSharedSettings
				Changed    = $false
				Scope      = 'FileUserShared'
			}
		}

		$fileSystemSettings = @()
		if (Test-Path (Join-Path $script:path_FileSystem "psf_config.json")) { $fileSystemSettings = Get-Content (Join-Path $script:path_FileSystem "psf_config.json") -Encoding UTF8 | ConvertFrom-Json }
		if ($fileSystemSettings) {
			$pathProperties['FileSystem'] = [pscustomobject]@{
				Path       = (Join-Path $script:path_FileSystem "psf_config.json")
				Properties = $fileSystemSettings
				Changed    = $false
				Scope      = 'FileSystem'
			}
		}
		#endregion Initialize Collection
	}
	process {
		if (Test-PSFFunctionInterrupt) { return }
		
		foreach ($item in $ConfigurationItem) {
			Remove-PersistedConfig -FullName $item.FullName -Scope $Scope -FileConfig $pathProperties
		}

		foreach ($item in $PersistedItem) {
			Remove-PersistedConfig -FullName $item.FullName -Scope $item.Scope -FileConfig $pathProperties
		}
		
		foreach ($item in $FullName) {
			# Ignore string-casted configurations
			if ($item -ceq "PSFramework.Configuration.Config") { continue }
			if ($item -ceq "PSFramework.Configuration.PersistedConfig") { continue }
			
			Remove-PersistedConfig -FullName $item -Scope $Scope -FileConfig $pathProperties
		}
		
		if ($Module) {
			$compoundName = "{0}.{1}" -f $Module, $Name

			Remove-PersistedConfig -FullName $compoundName -Scope $Scope -FileConfig $pathProperties
		}
	}
	end {
		if (Test-PSFFunctionInterrupt) { return }
		
		foreach ($fileConfig in $pathProperties.Values) {
			if (-not $fileConfig.Changed) { continue }
			
			if ($fileConfig.Properties) {
				$fileConfig.Properties | ConvertTo-Json | Set-Content -Path $fileConfig.Path -Encoding UTF8
			}
			else {
				Remove-Item $fileConfig.Path
			}
		}
	}
}
