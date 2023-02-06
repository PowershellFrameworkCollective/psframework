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
	
	.PARAMETER InstanceName
		A description of the InstanceName parameter.
	
	.PARAMETER Enabled
		Whether the provider should be enabled or disabled.
	
	.PARAMETER IncludeModules
		Only messages from modules listed here will be logged.
		Exact match only, an empty list results in all modules being logged.
	
	.PARAMETER ExcludeModules
		Messages from excluded modules will not be logged using this provider.
		Overrides -IncludeModules in case of overlap.
	
	.PARAMETER IncludeFunctions
		Only messages from functions that match at least one entry noted here will be logged.
		Uses wildcard expressions.
	
	.PARAMETER ExcludeFunctions
		Messages from functions that match at least one entry noted here will NOT be logged.
		Uses wildcard expressions.
	
	.PARAMETER IncludeRunspaces
		Only messages that come from one of the defined runspaces will be logged.
	
	.PARAMETER ExcludeRunspaces
		Messages that come from one of the defined runspaces will NOT be logged.
	
	.PARAMETER IncludeTags
		Only messages containing the listed tags will be logged.
		Exact match only, only a single match is required for a message to qualify.
	
	.PARAMETER ExcludeTags
		Messages containing any of the listed tags will not be logged.
		Overrides -IncludeTags in case of overlap.
	
	.PARAMETER MinLevel
		The minimum level of a message that will be logged.
		Note: The lower the message level, the MORE important it is.
		Levels range from 1 through 9:
		- InternalComment: 9
		- Debug: 8
		- Verbose: 5
		- Host: 2
		- Critical: 1
		The level "Warning" is not represented on this scale.
	
	.PARAMETER MaxLevel
		The maximum level of a message that will be logged.
		Note: The lower the message level, the MORE important it is.
		Levels range from 1 through 9:
		- InternalComment: 9
		- Debug: 8
		- Verbose: 5
		- Host: 2
		- Critical: 1
		The level "Warning" is not represented on this scale.
	
	.PARAMETER RequiresInclude
		By default, messages will be written to a logging provider, unless a specific exclude rule was met or any include rule was not met.
		That means, if no exclude and include rules exist at a given time, all messages will be written to the logging provider instance.
		Setting this to true will instead require at least one include rule to exist - and be met - before logging a message.
		This is designed for in particular for runspace-bound logging providers, which might at runtime swiftly gain or lose included runspaces.
	
	.PARAMETER ExcludeWarning
		Whether to exclude warnings from the logging provider / instance.
	
	.PARAMETER ExcludeError
		Whether to exclude errors from the logging provider / instance.
	
	.PARAMETER Wait
		Whether to have the command wait until the provider instance is provisioned and ready to handle messages.
		By default, the asynchroneous nature of the logging system my cause a slight delay, that in some instances could lead to missing the first few messages.
		Enables the logging runspace if disabled, may timeout (30 seconds) in extreme-load situations caused by other runspaces.
	
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
		$IncludeFunctions,
		
		[string[]]
		$ExcludeFunctions,
		
		[guid[]]
		$IncludeRunspaces,
		
		[guid[]]
		$ExcludeRunspaces,
		
		[string[]]
		$IncludeTags,
		
		[string[]]
		$ExcludeTags,
		
		[ValidateRange(1,9)]
		[int]
		$MinLevel,
		
		[ValidateRange(1, 9)]
		[int]
		$MaxLevel,
		
		[switch]
		$RequiresInclude,
		
		[switch]
		$ExcludeWarning,
		
		[switch]
		$ExcludeError,
		
		[switch]
		$Wait,
		
		[switch]
		$EnableException
	)
	
	dynamicparam
	{
		if ($Name -and ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name)))
		{
			$provider = [PSFramework.Logging.ProviderHost]::Providers[$Name]
			$results = $provider.ConfigurationParameters.InvokeGlobal() | Where-Object { $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] }
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
		if (-not ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name)))
		{
			Stop-PSFFunction -String 'Set-PSFLoggingProvider.Provider.NotFound' -StringValues $Name -EnableException $EnableException -Category InvalidArgument -Target $Name
			return
		}
		
		$provider = [PSFramework.Logging.ProviderHost]::Providers[$Name]
		if ($InstanceName -and $provider.ProviderVersion -eq 'Version_1')
		{
			Stop-PSFFunction -String 'Set-PSFLoggingProvider.Provider.V1NoInstance' -StringValues $Name -EnableException $EnableException -Category InvalidArgument -Target $Name
			return
		}
		
		[PSFramework.Utility.UtilityHost]::ImportScriptBlock($provider.IsInstalledScript, $true)
		
		if ((-not $provider.Enabled) -and (-not $provider.IsInstalledScript.InvokeGlobal()) -and $Enabled)
		{
			Stop-PSFFunction -String 'Set-PSFLoggingProvider.Provider.NotInstalled' -StringValues $Name -EnableException $EnableException -Category InvalidOperation -Target $Name
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		$provider.ConfigurationScript.InvokeGlobal($PSBoundParameters)
		
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
		$setProperty = -not $InstanceName -or $InstanceName -eq "Default"
		if (Test-PSFParameterBinding -ParameterName "IncludeModules")
		{
			if ($setProperty) { $provider.IncludeModules = $IncludeModules }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)IncludeModules" -Value $IncludeModules
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeModules")
		{
			if ($setProperty) { $provider.ExcludeModules = $ExcludeModules }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)ExcludeModules" -Value $ExcludeModules
		}
		
		if (Test-PSFParameterBinding -ParameterName "IncludeFunctions")
		{
			if ($setProperty) { $provider.IncludeFunctions = $IncludeFunctions }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)IncludeFunctions" -Value $IncludeFunctions
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeFunctions")
		{
			if ($setProperty) { $provider.ExcludeFunctions = $ExcludeFunctions }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)ExcludeFunctions" -Value $ExcludeFunctions
		}
		
		if (Test-PSFParameterBinding -ParameterName "IncludeRunspaces")
		{
			if ($setProperty) { $provider.IncludeRunspaces = $IncludeRunspaces }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)IncludeRunspaces" -Value $IncludeRunspaces
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeRunspaces")
		{
			if ($setProperty) { $provider.ExcludeRunspaces = $ExcludeRunspaces }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)ExcludeRunspaces" -Value $ExcludeRunspaces
		}
		
		if (Test-PSFParameterBinding -ParameterName "IncludeTags")
		{
			if ($setProperty) { $provider.IncludeTags = $IncludeTags }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)IncludeTags" -Value $IncludeTags
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeTags")
		{
			if ($setProperty) { $provider.ExcludeTags = $ExcludeTags }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)ExcludeTags" -Value $ExcludeTags
		}
		
		if ($MinLevel)
		{
			if ($setProperty) { $provider.MinLevel = $MinLevel }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)MinLevel" -Value $MinLevel
		}
		if ($MaxLevel)
		{
			if ($setProperty) { $provider.MaxLevel = $MaxLevel }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)MaxLevel" -Value $MaxLevel
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeWarning")
		{
			if ($setProperty) { $provider.IncludeWarning = -not $ExcludeWarning }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)IncludeWarning" -Value (-not $ExcludeWarning)
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeError")
		{
			if ($setProperty) { $provider.IncludeError = -not $ExcludeError }
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)IncludeError" -Value (-not $ExcludeError)
		}
		
		# V2 Only
		if (Test-PSFParameterBinding -ParameterName "RequiresInclude"){
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).$($instanceAffix)RequiresInclude" -Value $RequiresInclude
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
	end {
		if (Test-PSFFunctionInterrupt) { return }
		if (-not $Wait) { return }
		
		$limit = (Get-Date).AddSeconds(30)
		Start-PSFRunspace -Name 'psframework.logging' -NoMessage
		try { [PSFramework.Logging.ProviderHost]::WaitNextCycle($limit) }
		catch { Write-PSFMessage -Level Warning -String 'Set-PSFLoggingProvider.Wait.Timeout' -StringValues $Name, $InstanceName }
		Start-Sleep -Milliseconds 500
	}
}