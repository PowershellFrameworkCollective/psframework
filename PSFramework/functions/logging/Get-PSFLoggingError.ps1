function Get-PSFLoggingError {
	<#
	.SYNOPSIS
		Retrieve errors that happened when trying to log messages.
	
	.DESCRIPTION
		Retrieve errors that happened when trying to log messages.
		This command is used to troubleshoot issues with the logging system itself.

		It can only return errors that happened during the current process.
		Only logging instances that are currently enabled are considered, does not work for Legacy Logging Providers.
	
	.EXAMPLE
		PS C:\> Get-PSFLoggingError
		
		Returns all errors any currently enabled logging providers had.
	#>
	[CmdletBinding()]
	param (
		
	)
	process {
		$errors = foreach ($instance in Get-PSFLoggingProviderInstance) {
			if (-not $instance.Enabled) { continue }
			$instance.GetError()
		}

		$errors | Sort-Object Timestamp
	}
}