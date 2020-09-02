<#
This script publishes the module to the gallery.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$ApiKey,
	
	$WorkingDirectory,
	
	$Repository = 'PSGallery',
	
	[switch]
	$LocalRepo,
	
	[switch]
	$SkipPublish,
	
	[switch]
	$AutoVersion
)

#region Handle Working Directory Defaults
if (-not $WorkingDirectory)
{
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS)
	{
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else { $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY }
}
if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path $PSScriptRoot }
#endregion Handle Working Directory Defaults

# Prepare publish folder
Write-Host "Creating and populating publishing directory"
$publishDir = New-Item -Path $WorkingDirectory -Name publish -ItemType Directory -Force
Copy-Item -Path "$($WorkingDirectory)\PSFramework" -Destination $publishDir.FullName -Recurse -Force

#region Gather text data to compile
$text = @()
$processed = @()

# Gather Stuff to run before
foreach ($filePath in (& "$($PSScriptRoot)\..\PSFramework\internal\scripts\preimport.ps1"))
{
	if ([string]::IsNullOrWhiteSpace($filePath)) { continue }
	
	$item = Get-Item $filePath
	if ($item.PSIsContainer) { continue }
	if ($item.FullName -in $processed) { continue }
	$text += [System.IO.File]::ReadAllText($item.FullName)
	$processed += $item.FullName
}

# Gather commands
Get-ChildItem -Path "$($publishDir.FullName)\PSFramework\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($publishDir.FullName)\PSFramework\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather stuff to run afterwards
foreach ($filePath in (& "$($PSScriptRoot)\..\PSFramework\internal\scripts\postimport.ps1"))
{
	if ([string]::IsNullOrWhiteSpace($filePath)) { continue }
	
	$item = Get-Item $filePath
	if ($item.PSIsContainer) { continue }
	if ($item.FullName -in $processed) { continue }
	$text += [System.IO.File]::ReadAllText($item.FullName)
	$processed += $item.FullName
}
#endregion Gather text data to compile

#region Update the psm1 file
$fileData = Get-Content -Path "$($publishDir.FullName)\PSFramework\PSFramework.psm1" -Raw
$fileData = $fileData.Replace('"<was not compiled>"', '"<was compiled>"')
$fileData = $fileData.Replace('"<compile code into here>"', ($text -join "`n`n"))
[System.IO.File]::WriteAllText("$($publishDir.FullName)\PSFramework\PSFramework.psm1", $fileData, [System.Text.Encoding]::UTF8)
#endregion Update the psm1 file

#region Updating the Module Version
if ($AutoVersion)
{
	Write-Host "Updating module version numbers."
	try { [version]$remoteVersion = (Find-Module 'PSFramework' -Repository $Repository -ErrorAction Stop).Version }
	catch
	{
		Stop-PSFFunction -Message "Failed to access $($Repository)" -EnableException $true -ErrorRecord $_
	}
	if (-not $remoteVersion)
	{
		Stop-PSFFunction -Message "Couldn't find PSFramework on repository $($Repository)" -EnableException $true
	}
	$newBuildNumber = $remoteVersion.Build + 1
	[version]$localVersion = (Import-PowerShellDataFile -Path "$($publishDir.FullName)\PSFramework\PSFramework.psd1").ModuleVersion
	Update-ModuleManifest -Path "$($publishDir.FullName)\PSFramework\PSFramework.psd1" -ModuleVersion "$($localVersion.Major).$($localVersion.Minor).$($newBuildNumber)"
}
#endregion Updating the Module Version

#region Publish
if ($SkipPublish) { return }
if ($LocalRepo)
{
	# Dependencies must go first
	Write-Host "Creating Nuget Package for module: PSFramework"
	New-PSMDModuleNugetPackage -ModulePath (Get-Module -Name PSFramework).ModuleBase -PackagePath .
	Write-Host "Creating Nuget Package for module: PSFramework"
	New-PSMDModuleNugetPackage -ModulePath "$($publishDir.FullName)\PSFramework" -PackagePath .
}
else
{
	# Publish to Gallery
	Write-Host "Publishing the PSFramework module to $($Repository)"
	Publish-Module -Path "$($publishDir.FullName)\PSFramework" -NuGetApiKey $ApiKey -Force -Repository $Repository
}
#endregion Publish