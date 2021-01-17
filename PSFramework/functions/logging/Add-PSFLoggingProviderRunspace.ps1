function Add-PSFLoggingProviderRunspace
{
<#
	.SYNOPSIS
		Adds a runspace to the list of dynamically included runspaces of an active logging provider instance.
	
	.DESCRIPTION
		Adds a runspace to the list of dynamically included runspaces of an active logging provider instance.
		This is designed to allow runspaces to add themselves "on the fly" to a specific logging provider.
	
		Consider this scenario:
		You have a large workload you spread across many runspaces.
		However, each workload item might perform one out of three different categories of tasks.
		You want each of these categories to log into a dedicated logfile and have prepared a provider for each.
		Set each such logging instance as "-RequiresInclude" so by default nothing gets logged to any of them.
		Then each workload item can call this command to add itself to the correct logging provider instance.
	
		When done, call "Remove-PSFLoggingProviderRunspace" to remove that runspace correctly from the instance.
		When using runspaces with a runspace pool, runspaces might be recycled for workitems of other categories, so cleaning it up is a useful habit.
	
		Note:
		This call will fail if the instance has not been created yet!
		After setting up the logging provider instance using Set-PSFLoggingProvider, a short delay may occur before the instance is created.
		With the default configuration, this delay should be no worse than 6 seconds and generally a lot less.
		You can use "Get-PSFLoggingProviderInstance -ProviderName <providername> -Name <instancename>" to check whether it has been created.
	
	.PARAMETER ProviderName
		Name of the logging provider the instance is part of.
	
	.PARAMETER InstanceName
		Name of the logging provider instance to target.
		Default: "default"  (the instance created when you omit the instancename parameter on Set-PSFLoggingProvider)
	
	.PARAMETER Runspace
		The Runspace ID of the runspace to add.
		Defaults to the current runspace.
	
	.EXAMPLE
		PS C:\> Add-PSFLoggingProviderRunspace -ProviderName 'logfile' -InstanceName UpdateTask
	
		Adds the current runspace to the list of included runspaces on the logfile instance "UpdateTask".
#>
	[CmdletBinding()]
	param (
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
		if (-not $instance) {
			Stop-PSFFunction -String 'Add-PSFLoggingProviderRunspace.Instance.NotFound' -StringValues $ProviderName, $InstanceName -EnableException $true -Category ObjectNotFound -Cmdlet $PSCmdlet
		}
		
		$instance.AddRunspace($Runspace)
	}
}