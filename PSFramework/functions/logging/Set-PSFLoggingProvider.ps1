function Set-PSFLoggingProvider
{
<#
	.SYNOPSIS
		Configures a logging provider.
	
	.DESCRIPTION
		This command allows configuring the way a logging provider works.
		This grants the ability to ...
		- Enable / Disable a provider
		- Set additional parameters defined by the provider (each provider may implement its own settings, exposed through dynamic parameters)
		- Configure filters about what messages get sent to a given provider.
	
	.PARAMETER Name
		The name of the provider to configure
	
	.PARAMETER Enabled
		Whether the provider should be enabled or disabled.
	
	.PARAMETER IncludeModules
		Only messages from modules listed here will be logged.
		Exact match only, an empty list results in all modules being logged.
	
	.PARAMETER ExcludeModules
		Messages from excluded modules will not be logged using this provider.
		Overrides -IncludeModules in case of overlap.
	
	.PARAMETER IncludeTags
		Only messages containing the listed tags will be logged.
		Exact match only, only a single match is required for a message to qualify.
	
	.PARAMETER ExcludeTags
		Messages containing any of the listed tags will not be logged.
		Overrides -IncludeTags in case of overlap.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Set-PSFLoggingProvider -Name filesystem -Enabled $false
		
		Disables the filesystem provider.
	
	.EXAMPLE
		PS C:\> Set-PSFLoggingProvider -Name filesystem -ExcludeModules "PSFramework"
	
		Prevents all messages from the PSFramework module to be logged to the file system
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFLoggingProvider')]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name,
		
		[string]
		$InstanceName,
		
		[bool]
		$Enabled,
		
		[string[]]
		$IncludeModules,
		
		[string[]]
		$ExcludeModules,
		
		[string[]]
		$IncludeTags,
		
		[string[]]
		$ExcludeTags,
		
		[switch]
		$EnableException
	)
	
	dynamicparam
	{
		New-Variable -Name provider -Scope Private -Force

		if ($Name -and ([PSFramework.Logging.ProviderHost]::Providers.TryGetValue($Name, [ref]$provider)))
		{
			[PSFramework.Utility.UtilityHost]::ImportScriptBlock($provider.ConfigurationParameters, $true)
			$results = $provider.ConfigurationParameters.Invoke() | Where-Object { $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] }
			if (-not $results) { $results = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary }
			
			#region Process V2 Properties
			# Since V1 Providers do not have the property, this loop will never execute for them
			foreach ($propertyName in $provider.InstanceProperties)
			{
				$parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
				$parameterAttribute.ParameterSetName = '__AllParameterSets'
				$attributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
				$attributesCollection.Add($parameterAttribute)
				$RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter($propertyName, [object], $attributesCollection)
				
				$results.Add($propertyName, $RuntimeParam)
			}
			#endregion Process V2 Properties
			
			$results
		}
	}
	
	begin
	{
		New-Variable -Name provider -Scope Private -Force

		if (-not ([PSFramework.Logging.ProviderHost]::Providers.TryGetValue($Name, [ref]$provider)))
		{
			Stop-PSFFunction -String 'Set-PSFLoggingProvider.Provider.NotFound' -StringValues $Name -EnableException $EnableException -Category InvalidArgument -Target $Name
			return
		}
		
		if ($InstanceName -and $provider.ProviderVersion -eq 'Version_1')
		{
			Stop-PSFFunction -String 'Set-PSFLoggingProvider.Provider.V1NoInstance' -StringValues $Name -EnableException $EnableException -Category InvalidArgument -Target $Name
			return
		}
		
		[PSFramework.Utility.UtilityHost]::ImportScriptBlock($provider.IsInstalledScript, $true)
		
		if ((-not $provider.Enabled) -and (-not $provider.IsInstalledScript.Invoke()) -and $Enabled)
		{
			Stop-PSFFunction -String 'Set-PSFLoggingProvider.Provider.NotInstalled' -StringValues $Name -EnableException $EnableException -Category InvalidOperation -Target $Name
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		# Recreating the scriptblock this way ensures that it can properly inherit the variables in the current scope
		[System.Management.Automation.ScriptBlock]::Create($provider.ConfigurationScript).Invoke()
		
		$instanceAffix = ''
		if ($InstanceName -and ($InstanceName -ne "Default")) { $instanceAffix = "$InstanceName." }
		
		#region V2 Instance Properties
		foreach ($propertyName in $provider.InstanceProperties)
		{
			$value = $provider.ConfigurationDefaultValues[$propertyName]
			$initialize = $true
			if (Test-PSFParameterBinding -ParameterName $propertyName)
			{
				$initialize = $false
				$value = $PSBoundParameters[$propertyName]
			}
			
			Set-PSFConfig -FullName "$($provider.ConfigurationRoot).$($instanceAffix)$($propertyName)" -Value $value -Initialize:$initialize
		}
		#endregion V2 Instance Properties
		
		#region Filter Configuration
		if (Test-PSFParameterBinding -ParameterName "IncludeModules")
		{
			$provider.IncludeModules = $IncludeModules
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)IncludeModules" -Value $IncludeModules
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeModules")
		{
			$provider.ExcludeModules = $ExcludeModules
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)ExcludeModules" -Value $ExcludeModules
		}
		
		if (Test-PSFParameterBinding -ParameterName "IncludeTags")
		{
			$provider.IncludeTags = $IncludeTags
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)IncludeTags" -Value $IncludeTags
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeTags")
		{
			$provider.ExcludeTags = $ExcludeTags
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)ExcludeTags" -Value $ExcludeTags
		}
		#endregion Filter Configuration
		
		if (Test-PSFParameterBinding -ParameterName "Enabled")
		{
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)Enabled" -Value $Enabled
			if ($provider.ProviderVersion -eq 'Version_1') { $provider.Enabled = $Enabled }
			elseif ($provider.Instances[$InstanceName])
			{
				$provider.Instances[$InstanceName].Enabled = $Enabled
			}
		}
	}
}
