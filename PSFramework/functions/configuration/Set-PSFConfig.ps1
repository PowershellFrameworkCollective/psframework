function Set-PSFConfig
{
	<#
		.SYNOPSIS
			Sets configuration entries.
		
		.DESCRIPTION
			This function creates or changes configuration values.
			These can be used to provide dynamic configuration information outside the PowerShell variable system.
		
		.PARAMETER Name
			Name of the configuration entry. If an entry of exactly this non-casesensitive name already exists, its value will be overwritten.
			Duplicate names across different modules are possible and will be treated separately.
			If a name contains namespace notation and no module is set, the first namespace element will be used as module instead of name. Example:
			-Name "Nordwind.Server"
			Is Equivalent to
			-Name "Server" -Module "Nordwind"
		
		.PARAMETER Value
			The value to assign to the named configuration element.
		
		.PARAMETER Module
			This allows grouping configuration elements into groups based on the module/component they server.
			If this parameter is not set, the configuration element is stored under its name only, which increases the likelyhood of name conflicts in large environments.
    
        .PARAMETER Description
            Using this, the configuration setting is given a description, making it easier for a user to comprehend, what a specific setting is for.
		
		.PARAMETER Hidden
			Setting this parameter hides the configuration from casual discovery. Configurations with this set will only be returned by Get-Config, if the parameter "-Force" is used.
			This should be set for all system settings a user should have no business changing (e.g. for Infrastructure related settings such as mail server).
		
		.PARAMETER Default
			Setting this parameter causes the system to treat this configuration as a default setting. If the configuration already exists, no changes will be performed.
			Useful in scenarios where for some reason it is not practical to automatically set defaults before loading userprofiles.
    
        .PARAMETER EnableException
            Replaces user friendly yellow warnings with bloody red exceptions of doom!
            Use this if you want the function to throw terminating errors you want to catch.
    
        .PARAMETER DisableHandler
            This parameter disables the configuration handlers.
            Configuration handlers are designed to automatically validate and process input set to a config value, in addition to writing the value.
            In many cases, this is used to improve performance, by forking the value location also to a static C#-field, which is then used, rather than searching a Hashtable.
            Sometimes it may only be used to introduce input validation.
            Normally these shouldn't be circumvented, but just in case, it can be disabled.
	
		.PARAMETER Initialize
			Use this when setting configurations as part of module import.
			When initializing a configuration, it will only do a thing if the configuration hasn't already been initialized (So if you load the module multiple times or in multiple runspaces, it won't make a difference)
			Also, if there already was a non-initialized setting set for a given configuration, it will then try to set the old value again.
			This value will be processed by handlers, if any are set.
	
		.EXAMPLE
			PS C:\> Set-DbaConfig -Name 'User' -Value "Friedrich" -Description "The user under which the show must go on."
	
			Creates a configuration entry named "User" with the value "Friedrich"
	
		.EXAMPLE
			PS C:\> Set-DbaConfig -Name 'mymodule.User' -Value "Friedrich" -Description "The user under which the show must go on." -Handler $scriptBlock -Initialize
	
			Creates a configuration entry ...
			- Named "mymodule.user"
			- With the value "Friedrich"
			- It adds a description as noted
			- It registers the scriptblock stored in $scriptBlock as handler
			- It initializes the script. This block only executes the first time a it is run like this. SUbsequent calls will be ignored.
			This is the default example for modules using the configuration system.
			Note: While the -Handler parameter is optional, it is important to add it at the initial initialize call, if you are planning to add it.
			Only then will the system validate previous settings (such as what a user might have placed in his user profile)
	
		.EXAMPLE
			PS C:\> Set-DbaConfig 'ConfigLink' 'https://www.example.com/config.xml' 'Company' -Hidden
	
			Creates a configuration entry named "ConfigLink" in the "Company" module with the value 'https://www.example.com/config.xml'.
			This entry is hidden from casual discovery using Get-Config.
	
		.EXAMPLE
			PS C:\> Set-DbaConfig 'Network.Firewall' '10.0.0.2' -Default
	
			Creates a configuration entry named "Firewall" in the "Network" module with the value '10.0.0.2'
			This is only set, if the setting does not exist yet. If it does, this command will apply no changes.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Name,
		
		[Parameter(Position = 1)]
		[AllowNull()]
		[AllowEmptyCollection()]
		[AllowEmptyString()]
		$Value,
		
		[Parameter(Position = 2)]
		[string]
		$Module,
		
		[string]
		$Description,
		
		[System.Management.Automation.ScriptBlock]
		$Handler,
		
		[switch]
		$Hidden,
		
		[switch]
		$Default,
		
		[switch]
		$Initialize,
		
		[switch]
		$DisableHandler,
		
		[switch]
		$EnableException
	)
	
	#region Prepare Names
	$Name = $Name.ToLower()
	if ($Module) { $Module = $Module.ToLower() }
	
	if (-not $PSBoundParameters.ContainsKey("Module") -and ($Name -match ".+\..+"))
	{
		$r = $Name | select-string "^(.+?)\..+" -AllMatches
		$Module = $r.Matches[0].Groups[1].Value
		$Name = $Name.Substring($Module.Length + 1)
	}
	
	If ($Module) { $FullName = $Module, $Name -join "." }
	else { $FullName = $Name }
	#endregion Prepare Names
	
	#region Prepare runtime and kill execution as needed
	if ([PSFramework.Configuration.ConfigurationHost]::Configurations.ContainsKey($FullName))
	{
		$itExists = $true
		$itIsInitialized = [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName].Initialized
		$itIsEnforced = [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName].PolicyEnforced
	}
	else
	{
		$itExists = $false
		$itIsInitialized = $false
		$itIsEnforced = $false
	}
	
	if ($itExists -and $Default) { return }
	if ($itIsInitialized -and $Initialize) { return }
	if ($itIsEnforced -and (-not $Initialize))
	{
		Stop-PSFFunction -Message "Could not update configuration due to policy settings: $FullName" -EnableException $EnableException -Category PermissionDenied
		return
	}
	#endregion Prepare runtime and kill execution as needed
	
	#region Initializing a configuration
	if ($Initialize)
	{
		if ($itExists)
		{
			$oldValue = [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName].Value
			$cfg = [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName]
		}
		else { $cfg = New-Object PSFramework.Configuration.Config }
		$cfg.Name = $Name
		$cfg.Module = $Module
		$cfg.Description = $Description
		$cfg.Value = $Value
		$cfg.Handler = $Handler
		$cfg.Hidden = $Hidden
		$cfg.Initialized = $true
		[PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName] = $cfg
		
		if ($itExists) { Set-PSFConfig -Name $FullName -Value $oldValue }
	}
	#endregion Initializing a configuration

	#region Regular configuration update
	else
	{
		if (-not $itExists)
		{
			$cfg = New-Object PSFramework.Configuration.Config
			$cfg.Name = $Name
			$cfg.Module = $Module
			$cfg.Description = $Description
			$cfg.Handler = $Handler
			$cfg.Hidden = $Hidden
			[PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName] = $cfg
			
			Set-PSFConfig -Name $FullName -Value $Value
			return
		}
		
		else
		{
			[PSFramework.Configuration.Config]$cfg = [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName]
			if ((-not $DisableHandler) -and ($cfg.Handler) -and ($PSBoundParameters.ContainsKey("Value")))
			{
				$testResult = $cfg.Handler.Invoke($Value)
				if (-not $TestResult.Success)
				{
					Stop-PSFFunction -Message "Could not update configuration $FullName | Failed validation: $($testResult.Message)" -EnableException $EnableException -Category InvalidResult -Target $FullName
					return
				}
			}
			
			if ($PSBoundParameters.ContainsKey("Hidden")) { [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName].Hidden = $Hidden }
			if ($PSBoundParameters.ContainsKey("Value")) { [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName].Value = $Value }
			if ($PSBoundParameters.ContainsKey("Description")) { [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName].Description = $Description }
			if ($PSBoundParameters.ContainsKey("Handler")) { [PSFramework.Configuration.ConfigurationHost]::Configurations[$FullName].Handler = $Handler }
		}
	}
	#endregion Regular configuration update
}