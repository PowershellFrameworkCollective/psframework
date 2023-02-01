function Disable-PSFLoggingProvider {
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