$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = "0.10.27.134"

# Detect whether at some level dotsourcing was enforced
$script:doDotSource = $false
if ($psframework_dotsourcemodule) { $script:doDotSource = $true }
if (($PSVersionTable.PSVersion.Major -lt 6) -or ($PSVersionTable.OS -like "*Windows*"))
{
	if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\System" -Name "DoDotSource" -ErrorAction Ignore).DoDotSource) { $script:doDotSource = $true }
	if ((Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\System" -Name "DoDotSource" -ErrorAction Ignore).DoDotSource) { $script:doDotSource = $true }
}

<#
Note on Resolve-Path:
All paths are sent through Resolve-Path in order to convert them to the correct path separator.
This allows ignoring path separators throughout the import sequence, which could otherwise cause trouble depending on OS.
#>

# Detect whether at some level loading individual module files, rather than the compiled module was enforced
$importIndividualFiles = $false
if ($PSFramework_importIndividualFiles) { $importIndividualFiles = $true }
if (($PSVersionTable.PSVersion.Major -lt 6) -or ($PSVersionTable.OS -like "*Windows*"))
{
	if ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\System" -Name "ImportIndividualFiles" -ErrorAction Ignore).ImportIndividualFiles) { $script:doDotSource = $true }
	if ((Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\System" -Name "ImportIndividualFiles" -ErrorAction Ignore).ImportIndividualFiles) { $script:doDotSource = $true }
}
if (Test-Path (Join-Path (Resolve-Path -Path "$($script:ModuleRoot)\..") '.git')) { $importIndividualFiles = $true }
if (-not (Test-Path (Join-Path $script:ModuleRoot "commands.ps1"))) { $importIndividualFiles = $true }
	
function Import-ModuleFile
{
	<#
		.SYNOPSIS
			Loads files into the module on module import.
		
		.DESCRIPTION
			This helper function is used during module initialization.
			It should always be dotsourced itself, in order to proper function.
			
			This provides a central location to react to files being imported, if later desired
		
		.PARAMETER Path
			The path to the file to load
		
		.EXAMPLE
			PS C:\> . Import-ModuleFile -File $function.FullName
	
			Imports the file stored in $function according to import policy
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Path
	)
	
	if ($doDotSource) { . (Resolve-Path $Path) }
	else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText((Resolve-Path $Path)))), $null, $null) }
}

if ($importIndividualFiles)
{
	# Execute Preimport actions
	. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\preimport.ps1"
	
	# Import all internal functions
	foreach ($function in (Get-ChildItem "$($script:ModuleRoot)\internal\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore))
	{
		. Import-ModuleFile -Path $function.FullName
	}
	
	# Import all public functions
	foreach ($function in (Get-ChildItem "$($script:ModuleRoot)\functions" -Filter "*.ps1" -Recurse -ErrorAction Ignore))
	{
		. Import-ModuleFile -Path $function.FullName
	}
	
	# Execute Postimport actions
	. Import-ModuleFile -Path "$($script:ModuleRoot)\internal\scripts\postimport.ps1"
}
else
{
	if (Test-Path (Join-Path $script:ModuleRoot "resourcesBefore.ps1"))
	{
		. Import-ModuleFile -Path "$($script:ModuleRoot)\resourcesBefore.ps1"
	}
	
	. Import-ModuleFile -Path "$($script:ModuleRoot)\commands.ps1"
	
	if (Test-Path (Join-Path $script:ModuleRoot "resourcesAfter.ps1"))
	{
		. Import-ModuleFile -Path "$($script:ModuleRoot)\resourcesAfter.ps1"
	}
}