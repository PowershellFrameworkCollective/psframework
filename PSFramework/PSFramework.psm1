$script:PSFrameworkModuleRoot = $PSScriptRoot


# Import all public functions
foreach ($function in (Get-ChildItem "$PSFrameworkModuleRoot\functions\*\*.ps1"))
{
	$ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null)
}