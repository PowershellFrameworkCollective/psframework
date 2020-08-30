function Get-PSFLoggingProvider
{
<#
	.SYNOPSIS
		Returns a list of the registered logging providers.
	
	.DESCRIPTION
		Returns a list of the registered logging providers.
		Those are used to log messages to whatever system they are designed to log to.
	
		PSFramework ships with a few default logging providers.
		Custom logging destinations can be created by implementing your own, custom provider and registering it using Register-PSFLoggingProvider.
	
	.PARAMETER Name
		Default: '*'
		The name to filter by
	
	.EXAMPLE
		PS C:\> Get-PSFLoggingProvider
	
		Returns all logging provider
	
	.EXAMPLE
		PS C:\> Get-PSFLoggingProvider -Name filesystem
	
		Returns the filesystem provider
#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFLoggingProvider')]
	[OutputType([PSFramework.Logging.Provider])]
	Param (
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name = "*"
	)
	
	process
	{
		[PSFramework.Logging.ProviderHost]::Providers.Values | Where-Object Name -Like $Name | Sort-Object ProviderVersion, Name
	}
}