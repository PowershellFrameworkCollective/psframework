function Get-PSFLoggingProviderInstance
{
<#
	.SYNOPSIS
		Returns a list of the enabled logging provider instances.
	
	.DESCRIPTION
		Returns a list of the enabled logging provider instances.
		Those are used to log messages to whatever system they are designed to log to.
	
		PSFramework ships with a few default logging providers.
		Custom logging destinations can be created by implementing your own, custom provider and registering it using Register-PSFLoggingProvider.
	
	.PARAMETER ProviderName
		Default: '*'
		The name of the provider the instance is an instance of.
	
	.PARAMETER Name
		Default: '*'
		The name of the instance to filter by.
	
	.PARAMETER Force
		Enables returning disabled instances.
	
	.EXAMPLE
		PS C:\> Get-PSFLoggingProviderInstance
	
		Returns all enabled logging provider instances.
	
	.EXAMPLE
		PS C:\> Get-PSFLoggingProviderInstance -ProviderName logfile -Force
	
		Returns all logging provider instances - enabled or not - of the logfile provider
#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFLoggingProvider')]
	[OutputType([PSFramework.Logging.Provider])]
	param (
		[string]
		$ProviderName = '*',
		
		[string]
		$Name = '*',
		
		[switch]
		$Force
	)
	
	process
	{
		foreach ($provider in ([PSFramework.Logging.ProviderHost]::Providers.Values | Sort-Object Name))
		{
			if ($provider.ProviderVersion -lt 2) { continue }
			if ($provider.Name -notlike $ProviderName) { continue }
			
			foreach ($instance in ($provider.Instances.Values | Sort-Object Name))
			{
				if ($instance.Name -notlike $Name) { continue }
				if (-not ($instance.Enabled -or $Force)) { continue }
				$instance
			}
		}
	}
}