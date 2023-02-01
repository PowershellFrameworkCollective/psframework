function Disable-PSFLoggingProvider {
	<#
	.SYNOPSIS
		Disables the instance of a logging provider.
	
	.DESCRIPTION
		Disables the instance of a logging provider.
		This ensures all logs that apply to the logging provider are flushed and the closing events are properly released.
		For example, this ensures logfiles are complete and no longer in access.

		Only works for v2+ Logging Providers, as it addresses logging provider instances, not the provider itself.
	
	.PARAMETER Name
		Name of the logging provider to disable.
	
	.PARAMETER InstanceName
		Name of the instance of the logging provider to disable.
		Defaults to: Default
	
	.PARAMETER NoFinalizeWait
		Do not wait for the logging to conclude or the final events shutting down the provider instance to finish.
		By default, this command waits for all aspects of shutting down a logging instance to complete.
		Using this parameter is intended for situations where the powershell process continues and it is acceptable
		to continue while the shutting down happens in the background.
		
		Even with this parameter, all messages are flushed, so some waiting might be involved anyway,
		based on just how many log messages are still waiting to be processed.
	
	.EXAMPLE
		PS C:\> Disable-PSFLoggingProvider -Name logfile

		Disables the default instance of the logfile provider, then waits until all applicable logs are processed
		and the logfile is released.

	.EXAMPLE
		PS C:\> Disable-PSFLoggingProvider -Name logfile -InstanceName mytask

		Disables the "mytask" instance of the logfile provider, then waits until all applicable logs are processed
		and the logfile is released.

	.EXAMPLE
		PS C:\> Disable-PSFLoggingProvider -Name logfile -InstanceName mytask -NoFinalizeWait

		Disables the "mytask" instance of the logfile provider, then waits until all applicable logs are processed
		but not for the logfile to be released (which will happen soon after, in most cases).
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('PSFramework-logging-provider')]
		[ValidateNotNullOrEmpty()]
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name,
		
		[PsfArgumentCompleter('PSFramework-logging-instance-name2')]
		[string]
		$InstanceName = 'Default',

		[switch]
		$NoFinalizeWait
	)

	process {
		$limit = Get-Date
		$instances = Get-PSFLoggingProviderInstance -ProviderName $Name -Name $InstanceName

		foreach ($instance in $instances) {
			$instance.NotAfter = $limit
		}

		foreach ($instance in $instances) {
			$instance.Drain((-not $NoFinalizeWait))
		}
	}
}