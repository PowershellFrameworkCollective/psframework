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
	[CmdletBinding()]
	Param (
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name,
		
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
		if ($Name -and ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower())))
		{
			[scriptblock]::Create(([PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()].ConfigurationParameters)).Invoke()
		}
	}
	
	begin
	{
		if (-not ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower())))
		{
			Stop-PSFFunction -Message "Provider $Name not found!" -EnableException $EnableException -Category InvalidArgument -Target $Name -Depth 1
			return
		}
		
		[PSFramework.Logging.Provider]$provider = [PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()]
		
		if ((-not $provider.Enabled) -and (-not ([scriptblock]::Create($provider.IsInstalledScript).Invoke())) -and $Enabled)
		{
			Stop-PSFFunction -Message "Provider $Name not installed! Run 'Install-PSFLoggingProvider' first" -EnableException $EnableException -Category InvalidOperation -Target $Name -Depth 1
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		# Recreating the scriptblock this way ensures that it can properly inherit the variables in the current scope
		[System.Management.Automation.ScriptBlock]::Create($provider.ConfigurationScript).Invoke()
		
		#region Filter Configuration
		if (Test-PSFParameterBinding -ParameterName "IncludeModules")
		{
			$provider.IncludeModules = $IncludeModules
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeModules")
		{
			$provider.ExcludeModules = $ExcludeModules
		}
		
		if (Test-PSFParameterBinding -ParameterName "IncludeTags")
		{
			$provider.IncludeTags = $IncludeTags
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeTags")
		{
			$provider.ExcludeTags = $ExcludeTags
		}
		#endregion Filter Configuration
		
		if (Test-PSFParameterBinding -ParameterName "Enabled")
		{
			$provider.Enabled = $Enabled
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
	}
}