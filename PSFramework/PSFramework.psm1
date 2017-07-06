$script:PSFrameworkModuleRoot = $PSScriptRoot

# Detect whether at some level dotsourcing was enforced
$script:doDotSource = $false
if ($psframework_dotsourcemodule) { $script:doDotSource = $true }
if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\System" -Name "DoDotSource" -ErrorAction Ignore).DoDotSource) { $script:doDotSource = $true }
if ((Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\System" -Name "DoDotSource" -ErrorAction Ignore).DoDotSource) { $script:doDotSource = $true }

# Execute Preimport actions
if ($doDotSource) { . "$PSFrameworkModuleRoot\internal\scripts\preimport.ps1" }
else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText("$PSFrameworkModuleRoot\internal\scripts\preimport.ps1"))), $null, $null) }

# Import all internal functions
foreach ($function in (Get-ChildItem "$PSFrameworkModuleRoot\internal\functions\*\*.ps1"))
{
	if ($doDotSource) { . $function.FullName }
	else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null) }
}

# Import all public functions
foreach ($function in (Get-ChildItem "$PSFrameworkModuleRoot\functions\*\*.ps1"))
{
	if ($doDotSource) { . $function.FullName }
	else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($function))), $null, $null) }
}


# Execute Postimport actions
if ($doDotSource) { . "$PSFrameworkModuleRoot\internal\scripts\postimport.ps1" }
else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText("$PSFrameworkModuleRoot\internal\scripts\postimport.ps1"))), $null, $null) }