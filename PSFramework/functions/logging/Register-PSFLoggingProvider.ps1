function Register-PSFLoggingProvider
{
<#
	.SYNOPSIS
		Registers a new logging provider to the PSFramework logging system.
	
	.DESCRIPTION
		This function registers all components of the PSFramework logging provider systems.
		It allows you to define your own logging destination and configuration and tie them into the default logging system.
		
		In order to properly utilize its power, it becomes necessary to understand how the logging works beneath the covers:
		- On Start of the logging script, it runs a one-time scriptblock per enabled provider (this will also occur when later enabling a provider)
		- Thereafter the script will continue, logging in cycles of Start > Log all Messages > Log all Errors > End
		Each of those steps has its own event, allowing for fine control over what happens where.
		- Finally, on shutdown of a provider it again offers an option to execute some code (to dispose/free resources in use)
		
		NOTE: Logging Provider Versions
		There are two versions / generations of logging providers, that are fundamentally different from each other:
		
		Version 1
		---------
		
		All providers share the same scope for the execution of ALL of those actions/scriptblocks!
		This makes it important to give your variables/functions a unique name, in order to avoid conflicts.
		General Guideline:
		- All variables should start with the name of the provider and an underscore. Example: $filesystem_root
		- All functions should use the name of the provider as prefix. Example: Clean-FileSystemErrorXml
		
		Version 2
		---------
		
		Each provider runs in an isolated module context.
		A provider can have multiple instances of itself active at the same time, each with separate resource isolation.
		Additional tooling provided makes it also easier to publish complex logging providers.
		Share variables between events by making them script-scope (e.g.: $script:path)
	
	.PARAMETER Name
		A unique name for your provider. Registering a provider under a name already registered, NOTHING will happen.
		This function will instead silently terminate.
	
	.PARAMETER Version2
		Flags the provider as a second generation logging provider.
		This reduces the complexity and improves the overall user experience while adding multi-instance capability to the service.
		All new providers should be built as version2 providers.
		Generation 1 legacy providers are still supported under the PSFramework Reliability Promise
	
	.PARAMETER Enabled
		Setting this will enable the provider on registration.
	
	.PARAMETER ConfigurationRoot
		Provider instance information is stored in the configuration system.
		Assuming you would store the path location for the provider under this config setting:
		'PSFramework.Logging.LogFile.FilePath'
		Then the ConfigurationRoot would be:
		'PSFramework.Logging.LogFile'
		
		For more information on the configuration system, see:
		https://psframework.org/documentation/documents/psframework/configuration.html
	
	.PARAMETER InstanceProperties
		The properties needed to define an instance of a provider.
		Examples from the default providers:
		LogFile: 'CsvDelimiter','FilePath','FileType','Headers','IncludeHeader','Logname','TimeFormat'
		GELF: 'Encrypt','GelfServer','Port'
	
	.PARAMETER ConfigurationDefaultValues
		A hashtable containing the default values to assume when creating a new instance of a logging provider.
		This data is used during Set-PSFLoggingProvider when nothing in particular is specified for a given value.
		Instances that are defined through configuration are responsible for their full configuration set and will not be provided these values.
	
	.PARAMETER FunctionDefinitions
		If your provider instances need access to helper functions, the easiest way is to provide them using this parameter.
		Specify a scriptblock that contains your function statements with the full definition, they will be made available to the provider instances.
		Note: All logging provider instances are isolated from each other.
		Even though multiple instances will have access to equal instances, they will not share access to variables and such.
	
	.PARAMETER RegistrationEvent
		Scriptblock that should be executed on registration.
		This allows you to perform installation actions synchronously, with direct user interaction.
		At the same time, by adding it as this parameter, it will only performed on the initial registration, rather than every time the provider is registered (runspaces, Remove-Module/Import-Module)
	
	.PARAMETER BeginEvent
		The actions that should be taken once when setting up the logging.
		Can well be used to register helper functions or loading other resources that should be loaded on start only.
	
	.PARAMETER StartEvent
		The actions taken at the beginning of each logging cycle.
		Typically used to establish connections or do some necessary pre-connections.
	
	.PARAMETER MessageEvent
		The actions taken to process individual messages.
		The very act of writing logs.
		This scriptblock receives a message object (As returned by Get-PSFMessage) as first and only argument.
		Under some circumstances, this message may be a $null object, your scriptblock must be able to handle this.
	
	.PARAMETER ErrorEvent
		The actions taken to process individual error messages.
		The very act of writing logs.
		This scriptblock receives a message object (As returned by 'Get-PSFMessage -Errors') as first and only argument.
		Under some circumstances, this message may be a $null object, your scriptblock must be able to handle this.
		This consists of complex, structured data and may not be suitable to all logging formats.
		However all errors are ALWAYS accompanied by a message, making integrating this optional.
	
	.PARAMETER EndEvent
		Actions taken when finishing up a logging cycle. Can be used to close connections.
	
	.PARAMETER FinalEvent
		Final action to take when the logging terminates.
		This should release all resources reserved.
		This event will fire when:
		- The console is being closed
		- The logging script is stopped / killed
		- The logging provider is disabled
	
	.PARAMETER ConfigurationParameters
		The function Set-PSFLoggingProvider can be used to configure this logging provider.
		Using this parameter it is possible to register dynamic parameters when configuring your provider.
	
	.PARAMETER ConfigurationScript
		When using Set-PSFLoggingProvider, this script can be used to input given by the dynamic parameters generated by the -ConfigurationParameters parameter.
	
	.PARAMETER IsInstalledScript
		A scriptblock verifying that all prerequisites are properly installed.
	
	.PARAMETER InstallationScript
		A scriptblock performing the installation of the provider's prerequisites.
		Used by Install-PSFProvider in conjunction with the script provided by -InstallationParameters
	
	.PARAMETER InstallationParameters
		A scriptblock returning dynamic parameters that are offered when running Install-PSFprovider.
		Those can then be used by the installation scriptblock specified in the aptly named '-InstallationScript' parameter.
	
	.PARAMETER ConfigurationSettings
		This is executed before actually registering the scriptblock.
		It allows you to include any logic you wish, but it is specifically designed for configuration settings using Set-PSFConfig with the '-Initialize' parameter.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Register-PSFLoggingProvider -Name "filesystem" -Enabled $true -RegistrationEvent $registrationEvent -BeginEvent $begin_event -StartEvent $start_event -MessageEvent $message_Event -ErrorEvent $error_Event -EndEvent $end_event -FinalEvent $final_event -ConfigurationParameters $configurationParameters -ConfigurationScript $configurationScript -IsInstalledScript $isInstalledScript -InstallationScript $installationScript -InstallationParameters $installationParameters -ConfigurationSettings $configuration_Settings
		
		Registers the filesystem provider, providing events for every single occasion.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[PSFramework.PSFCore.NoJeaCommandAttribute()]
	[CmdletBinding(DefaultParameterSetName = 'Version1', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFLoggingProvider')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(ParameterSetName = 'Version2')]
		[switch]
		$Version2,
		
		[switch]
		$Enabled,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Version2')]
		[string]
		$ConfigurationRoot,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Version2')]
		[string[]]
		$InstanceProperties,
		
		[Parameter(ParameterSetName = 'Version2')]
		[Hashtable]
		$ConfigurationDefaultValues = @{ },
		
		[Parameter(ParameterSetName = 'Version2')]
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$FunctionDefinitions = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$RegistrationEvent,
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$BeginEvent = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$StartEvent = { },
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$MessageEvent,
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$ErrorEvent = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$EndEvent = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$FinalEvent = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$ConfigurationParameters = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$ConfigurationScript = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$IsInstalledScript = { $true },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$InstallationScript = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$InstallationParameters = { },
		
		[System.Management.Automation.ScriptBlock]
		[PsfValidateLanguageMode()]
		$ConfigurationSettings,
		
		[switch]
		$EnableException
	)
	
	if ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name))
	{
		return
	}
	
	if ($ConfigurationSettings) { & $ConfigurationSettings }
	if (Test-PSFParameterBinding -ParameterName Enabled)
	{
		Set-PSFConfig -FullName "LoggingProvider.$Name.Enabled" -Value $Enabled.ToBool() -DisableHandler
	}
	
	switch ($PSCmdlet.ParameterSetName)
	{
		#region Implement Version 1 Logging Provider (legacy)
		'Version1'
		{
			$provider = New-Object PSFramework.Logging.Provider
			$provider.Name = $Name
			$provider.BeginEvent = $BeginEvent
			$provider.StartEvent = $StartEvent
			$provider.MessageEvent = $MessageEvent
			$provider.ErrorEvent = $ErrorEvent
			$provider.EndEvent = $EndEvent
			$provider.FinalEvent = $FinalEvent
			$provider.ConfigurationParameters = $ConfigurationParameters
			$provider.ConfigurationScript = $ConfigurationScript
			$provider.IsInstalledScript = $IsInstalledScript
			$provider.InstallationScript = $InstallationScript
			$provider.InstallationParameters = $InstallationParameters
			
			$provider.IncludeModules = Get-PSFConfigValue -FullName "LoggingProvider.$Name.IncludeModules" -Fallback @()
			$provider.ExcludeModules = Get-PSFConfigValue -FullName "LoggingProvider.$Name.ExcludeModules" -Fallback @()
			$provider.IncludeTags = Get-PSFConfigValue -FullName "LoggingProvider.$Name.IncludeTags" -Fallback @()
			$provider.ExcludeTags = Get-PSFConfigValue -FullName "LoggingProvider.$Name.ExcludeTags" -Fallback @()
			
			$provider.InstallationOptional = Get-PSFConfigValue -FullName "LoggingProvider.$Name.InstallOptional" -Fallback $false
			
			[PSFramework.Logging.ProviderHost]::Providers[$Name] = $provider
		}
		#endregion Implement Version 1 Logging Provider (legacy)
		
		#region Implement Version 2 Logging Provider
		'Version2'
		{
			# Initialize default config for logging providers
			Set-PSFConfig -Module LoggingProvider -Name "$Name.Enabled" -Value $false -Initialize -Validation "bool" -Description "Whether the logging provider should be enabled on registration"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.AutoInstall" -Value $false -Initialize -Validation "bool" -Description "Whether the logging provider should be installed on registration"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.InstallOptional" -Value $false -Initialize -Validation "bool" -Description "Whether installing the logging provider is mandatory, in order for it to be enabled"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.IncludeModules" -Value @() -Initialize -Validation "stringarray" -Description "Module whitelist. Only messages from listed modules will be logged"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.ExcludeModules" -Value @() -Initialize -Validation "stringarray" -Description "Module blacklist. Messages from listed modules will not be logged"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.IncludeFunctions" -Value @() -Initialize -Validation "stringarray" -Description "Function whitelist. Only messages from listed functions will be logged"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.ExcludeFunctions" -Value @() -Initialize -Validation "stringarray" -Description "Function blacklist. Messages from listed functions will not be logged"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.IncludeTags" -Value @() -Initialize -Validation "stringarray" -Description "Tag whitelist. Only messages with these tags will be logged"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.ExcludeTags" -Value @() -Initialize -Validation "stringarray" -Description "Tag blacklist. Messages with these tags will not be logged"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.IncludeRunspaces" -Value @() -Initialize -Validation "guidarray" -Description "Runpace whitelist. Only messages from listed runspace guids will be logged"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.ExcludeRunspaces" -Value @() -Initialize -Validation "guidarray" -Description "Runpace blacklist. Messages from listed runspace guids will not be logged"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.IncludeWarning" -Value $true -Initialize -Validation "bool" -Description "Whether to log warning messages"
			Set-PSFConfig -Module LoggingProvider -Name "$Name.MinLevel" -Value 1 -Initialize -Validation "integer1to9" -Description "The minimum message level to include in logs. Lower means more important - eg: Verbose is level 5, Host is level 2. Levels range from 1 through 9, Warning level messages are not included in this scale."
			Set-PSFConfig -Module LoggingProvider -Name "$Name.MaxLevel" -Value 9 -Initialize -Validation "integer1to9" -Description "The maximum message level to include in logs. Lower means more important - eg: Verbose is level 5, Host is level 2. Levels range from 1 through 9, Warning level messages are not included in this scale."
			Set-PSFConfig -Module LoggingProvider -Name "$Name.RequiresInclude" -Value $false -Initialize -Validation "bool" -Description "Whether any include rule must exist - and be met - before a message is accepted for logging"
			
			# Initialize custom config defined by logging provider
			foreach ($property in $InstanceProperties)
			{
				Set-PSFConfig -FullName "$ConfigurationRoot.$property" -Value $ConfigurationDefaultValues[$property] -Initialize
			}
			
			$provider = New-Object PSFramework.Logging.ProviderV2
			$provider.Name = $Name
			$provider.ConfigurationRoot = $ConfigurationRoot.Trim('.')
			$provider.InstanceProperties = $InstanceProperties
			$provider.ConfigurationDefaultValues = $ConfigurationDefaultValues
			$provider.BeginEvent = $BeginEvent
			$provider.StartEvent = $StartEvent
			$provider.MessageEvent = $MessageEvent
			$provider.ErrorEvent = $ErrorEvent
			$provider.EndEvent = $EndEvent
			$provider.FinalEvent = $FinalEvent
			$provider.Functions = $FunctionDefinitions
			$provider.ConfigurationParameters = $ConfigurationParameters
			$provider.ConfigurationScript = $ConfigurationScript
			$provider.IsInstalledScript = $IsInstalledScript
			$provider.InstallationScript = $InstallationScript
			$provider.InstallationParameters = $InstallationParameters
			$provider.InstallationOptional = Get-PSFConfigValue -FullName "LoggingProvider.$Name.InstallOptional" -Fallback $false
			
			[PSFramework.Logging.ProviderHost]::Providers[$Name] = $provider
		}
		#endregion Implement Version 2 Logging Provider
	}
	
	
	try { if ($RegistrationEvent) { & $RegistrationEvent } }
	catch
	{
		$dummy = $null
		$null = [PSFramework.Logging.ProviderHost]::Providers.TryRemove($Name, [ref]$dummy)
		Stop-PSFFunction -String 'Register-PSFLoggingProvider.RegistrationEvent.Failed' -StringValues $Name -ErrorRecord $_ -EnableException $EnableException -Tag 'logging', 'provider', 'fail', 'register'
		return
	}
	
	#region Auto-Install & Enable
	$shouldEnable = Get-PSFConfigValue -FullName "LoggingProvider.$Name.Enabled" -Fallback $false
	$isInstalled = $provider.IsInstalledScript.InvokeGlobal()
	
	if (-not $isInstalled -and (Get-PSFConfigValue -FullName "LoggingProvider.$Name.AutoInstall" -Fallback $false))
	{
		try
		{
			Install-PSFLoggingProvider -Name $Name -EnableException
			$isInstalled = $provider.IsInstalledScript.InvokeGlobal()
		}
		catch
		{
			if ($provider.InstallationOptional)
			{
				Write-PSFMessage -Level Warning -String 'Register-PSFLoggingProvider.Installation.Failed' -StringValues $Name -ErrorRecord $_ -Tag 'logging', 'provider', 'fail', 'install' -EnableException $EnableException
			}
			else
			{
				Stop-PSFFunction -String 'Register-PSFLoggingProvider.Installation.Failed' -StringValues $Name -ErrorRecord $_ -EnableException $EnableException -Tag 'logging', 'provider', 'fail', 'install'
				return
			}
		}
	}
	
	if ($shouldEnable)
	{
		if ($isInstalled -or $provider.InstallationOptional) { $provider.Enabled = $true }
		else
		{
			Stop-PSFFunction -String 'Register-PSFLoggingProvider.NotInstalled.Termination' -StringValues $Name -ErrorRecord $_ -EnableException $EnableException -Tag 'logging', 'provider', 'fail', 'install'
			return
		}
	}
	#endregion Auto-Install & Enable
}