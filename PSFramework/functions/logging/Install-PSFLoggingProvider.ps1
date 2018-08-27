function Install-PSFLoggingProvider
{
	<#
		.SYNOPSIS
			Installs a logging provider for the PSFramework.
		
		.DESCRIPTION
			This command installs a logging provider registered with the PSFramework.
			
			Some providers may require special installation steps, that cannot be handled by the common initialization / configuration.
			For example, a provider may require installation of binaries that require elevation.
	
			In order to cover those scenarios, a provider can include an installation script, which is called by this function.
			It can also provide additional parameters to this command, which are dynamically provided once the -Name parameter has been passed.
	
			When registering the logging provider (Using Register-PSFLoggingProvider), you can specify the logic executed by this command with these parameters:
			- IsInstalledScript :      Must return $true when installation has already been performed. If this returns not $false, then this command will do nothing at all.
			- InstallationScript :     The script performing the actual installation
			- InstallationParameters : A script that returns dynamic parameters. This can be used to generate additional parameters that can modify the installation process.
			
			NOTE:
			This module does not contain help/guidance on how to generate dynamic parameters!
		
		.PARAMETER Name
			The name of the provider to install
		
		.PARAMETER EnableException
			This parameters disables user-friendly warnings and enables the throwing of exceptions.
			This is less user friendly, but allows catching exceptions in calling scripts.
	
		.EXAMPLE
			PS C:\> Install-PSFLoggingProvider -Name Eventlog
	
			Installs a logging provider named 'eventlog'
	#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Install-PSFLoggingProvider')]
	Param (
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name,
		
		[switch]
		$EnableException
	)
	
	dynamicparam
	{
		if ($Name -and ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower())))
		{
			[PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()].InstallationParameters.Invoke()
		}
	}
	
	begin
	{
		
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower())))
		{
			Stop-PSFFunction -Message "Provider $Name not found!" -EnableException $EnableException -Category InvalidArgument -Target $Name -Tag 'logging', 'provider', 'install'
			return
		}
		
		$provider = [PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()]
		
		if (-not ([System.Management.Automation.ScriptBlock]::Create($provider.IsInstalledScript).Invoke()))
		{
			try { [System.Management.Automation.ScriptBlock]::Create($provider.InstallationScript).Invoke() }
			catch
			{
				Stop-PSFFunction -Message "Failed to install provider '$Name'" -EnableException $EnableException -Target $Name -ErrorRecord $_ -Tag 'logging', 'provider', 'install'
				return
			}
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
	}
}
