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

	.PARAMETER InstanceObject
		A full Logging Provider Instance object, as return by Get-PSFLoggingProviderInstance

	.PARAMETER Config
		One or more configuration objects to disable.
		Each entry must provide the provider Name and may include a specific InstanceName.
		All other settings are ignored.
	
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

	.EXAMPLE
		PS C:\> Get-PSFLoggingProviderInstance | Disable-PSFLoggingProvider

		Disables all active logging provider instances

	.EXAMPLE
		PS C:\> Disable-PSFLoggingProvider -Config $config.Logging

		Disables all logging provider instances defined in $config.Logging
		This allows convenient logging configuration from a config file - it takes the same config data Set-PSFLoggingProvider accepts.
	#>
	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
		[PsfArgumentCompleter('PSFramework-logging-provider')]
		[ValidateNotNullOrEmpty()]
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name,
		
		[Parameter(ParameterSetName = 'ByName')]
		[PsfArgumentCompleter('PSFramework-logging-instance-name2')]
		[string]
		$InstanceName = 'Default',

		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByObject')]
		[PSFramework.Logging.ProviderInstance[]]
		$InstanceObject,

		[Parameter(Mandatory = $true, ParameterSetName = 'ByConfig')]
		[object[]]
		$Config,

		[switch]
		$NoFinalizeWait
	)

	begin {
		$inInstances = [System.Collections.ArrayList]@()
		$limit = Get-Date
	}
	process {
		if ($Name) {
			$instances = Get-PSFLoggingProviderInstance -ProviderName $Name -Name $InstanceName
			
			foreach ($instance in $instances) {
				$instance.NotAfter = $limit
			}
			
			$null = $inInstances.Add($instance)
		}

		foreach ($instance in $InstanceObject) {
			$instance.NotAfter = $limit
			$null = $inInstances.Add($instance)
		}

		foreach ($entry in $Config) {
			if ($null -eq $entry) { continue }
			$param = $entry | ConvertTo-PSFHashtable -Include Name, InstanceName -Remap ([ordered]@{ Name = 'ProviderName'; InstanceName = 'Name' })
			if (-not $param.Name) { $param.Name = 'Default' }

			$instances = Get-PSFLoggingProviderInstance @param
			
			foreach ($instance in $instances) {
				$instance.NotAfter = $limit
			}
			
			$null = $inInstances.Add($instance)
		}
	}
	end {
		# Prevent duplicate draining
		$drained = [System.Collections.ArrayList]@()
		
		foreach ($instance in $inInstances) {
			if ($instance -in $drained) { continue }
			$instance.Drain((-not $NoFinalizeWait))
			$null = $drained.Add($instance)
		}
	}
}