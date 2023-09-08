function Get-PSFConfig {
	<#
		.SYNOPSIS
			Retrieves configuration elements by name.
		
		.DESCRIPTION
			Retrieves configuration elements by name.
			Can be used to search the existing configuration list.
	
		.PARAMETER FullName
			Default: "*"
			Search for configurations using the full name
		
		.PARAMETER Name
			Default: "*"
			The name of the configuration element(s) to retrieve.
			May be any string, supports wildcards.
		
		.PARAMETER Module
			Default: "*"
			Search configuration by module.

		.PARAMETER Persisted
			Rather than retrieving current settings, look for configuration entries that have been persisted on the machine.
		
		.PARAMETER Force
			Overrides the default behavior and also displays hidden configuration values.
		
		.EXAMPLE
			PS C:\> Get-PSFConfig 'Mail.To'
			
			Retrieves the configuration element for the key "Mail.To"
	
		.EXAMPLE
			PS C:\> Get-PSFConfig -Force
	
			Retrieve all configuration elements from all modules, even hidden ones.

		.EXAMPLE
			PS C:\> Get-PSFConfig -Persisted

			Retrieve all persisted settings.
    #>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[OutputType([PSFramework.Configuration.Config])]
	[CmdletBinding(DefaultParameterSetName = "FullName", HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFConfig')]
	Param (
		[Parameter(ParameterSetName = "FullName", Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$FullName = "*",
		
		[Parameter(ParameterSetName = "Module", Position = 1)]
		[string]
		$Name = "*",
		
		[Parameter(ParameterSetName = "Module", Position = 0)]
		[string]
		$Module = "*",

		[switch]
		$Persisted,
		
		[switch]
		$Force
	)
	
	begin {
		function ConvertFrom-ConfigPersisted {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				[AllowNull()]
				$Settings,

				[PSFramework.Configuration.ConfigScope]
				$Scope
			)
			process {
				if (-not $Settings) { return }

				foreach ($value in $Settings.Values) {
					$cfgValue = $value.Value
					if ($value.KeepPersisted) {
						$cfgValue = [PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($value.Value)
					}

					New-Object PSFramework.Configuration.PersistedConfig -Property @{
						FullName = $value.FullName
						Scope    = $Scope
						Value    = $cfgValue
					}
				}
			}
		}
	}
	process {
		if ($Persisted) {
			$settings = foreach ($scope in [enum]::GetNames([PSFramework.Configuration.ConfigScope])) {
				Read-PsfConfigPersisted -Scope $scope | ConvertFrom-ConfigPersisted -Scope $scope
			}

			$filter = $FullName
			if ($PSCmdlet.ParameterSetName -eq 'Module') { $filter = "$Module.$Name" }
			$settings | Where-Object FullName -like $filter

			return
		}
		switch ($PSCmdlet.ParameterSetName) {
			"Module" {
				[PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object {
					($_.Name -like $Name) -and
					($_.Module -like $Module) -and
					((-not $_.Hidden) -or ($Force))
				} | Sort-Object Module, Name
			}
			
			"FullName" {
				[PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object {
					("$($_.Module).$($_.Name)" -like $FullName) -and
					((-not $_.Hidden) -or ($Force))
				} | Sort-Object Module, Name
			}
		}
	}
}
