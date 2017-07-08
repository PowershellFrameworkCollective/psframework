# Initialize the configurations
if ($doDotSource)
{
	foreach ($file in (Get-ChildItem -Path "$PSFrameworkModuleRoot\internal\configurations\*.ps1"))
	{
		. $file.FullName
	}
}
else
{
	foreach ($file in (Get-ChildItem -Path "$PSFrameworkModuleRoot\internal\configurations\*.ps1"))
	{
		$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($file.FullName))), $null, $null)
	}
}

# Import configuration settings from registry
if ($doDotSource) { . "$PSFrameworkModuleRoot\internal\scripts\loadConfigurationFromRegistry.ps1" }
else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText("$PSFrameworkModuleRoot\internal\scripts\loadConfigurationFromRegistry.ps1"))), $null, $null) }

# Start the logging system
if ($doDotSource) { . "$PSFrameworkModuleRoot\internal\scripts\async-logging.ps1" }
else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText("$PSFrameworkModuleRoot\internal\scripts\async-logging.ps1"))), $null, $null) }