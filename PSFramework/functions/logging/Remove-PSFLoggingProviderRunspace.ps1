function Remove-PSFLoggingProviderRunspace
{
<#
	.SYNOPSIS
		Removes a runspace from the list of dynamically included runspaces of an active logging provider instance.
	
	.DESCRIPTION
		Removes a runspace from the list of dynamically included runspaces of an active logging provider instance.
		See the help on Add-PSFLoggingProviderRunspace for details on how and why this is desirable.
	
	.PARAMETER ProviderName
		Name of the logging provider the instance is part of.
	
	.PARAMETER InstanceName
		Name of the logging provider instance to target.
		Default: "default"  (the instance created when you omit the instancename parameter on Set-PSFLoggingProvider)
	
	.PARAMETER Runspace
		The Runspace ID of the runspace to remove.
		Defaults to the current runspace.
	
	.EXAMPLE
		PS C:\> Remove-PSFLoggingProviderRunspace -ProviderName 'logfile' -InstanceName UpdateTask
	
		Removes the current runspace from the list of included runspaces on the logfile instance "UpdateTask".
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$ProviderName,
		
		[string]
		$InstanceName = 'default',
		
		[guid]
		$Runspace = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId
	)
	
	process
	{
		$instance = Get-PSFLoggingProviderInstance -ProviderName $ProviderName -Name $InstanceName
		if ($instance) {
			$instance.RemoveRunspace($Runspace)
		}
	}
}