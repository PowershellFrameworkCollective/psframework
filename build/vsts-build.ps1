<#
This script publishes the module to the gallery.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$ApiKey,
	
	$SkipPublish = $false,
	
	$RootPath = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
)

# Prepare publish folder
Write-Host "Creating and populating publishing directory"
$publishDir = New-Item -Path $RootPath -Name publish -ItemType Directory
Copy-Item -Path "$($RootPath)\PSFramework" -Destination $publishDir.FullName -Recurse -Force

# Create commands.ps1
Write-Host "Creating command.ps1"
$text = @()
Get-ChildItem -Path "$($publishDir.FullName)\PSFramework\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($publishDir.FullName)\PSFramework\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
$text -join "`n`n" | Set-Content -Path "$($publishDir.FullName)\PSFramework\commands.ps1"

# Create resourcesBefore.ps1
Write-Host "Creating resourcesBefore.ps1"
$processed = @()
$text = @()
foreach ($line in (Get-Content "$($PSScriptRoot)\filesBefore.txt" | Where-Object { $_ -notlike "#*" }))
{
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	$basePath = Join-Path "$($publishDir.FullName)\PSFramework" $line
	foreach ($entry in (Resolve-Path -Path $basePath))
	{
		$item = Get-Item $entry
		if ($item.PSIsContainer) { continue }
		if ($item.FullName -in $processed) { continue }
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
	}
}
if ($text) { $text -join "`n`n" | Set-Content -Path "$($publishDir.FullName)\PSFramework\resourcesBefore.ps1" }

# Create resourcesAfter.ps1
Write-Host "Creating resourcesAfter.ps1"
$processed = @()
$text = @()
foreach ($line in (Get-Content "$($PSScriptRoot)\filesAfter.txt" | Where-Object { $_ -notlike "#*" }))
{
	if ([string]::IsNullOrWhiteSpace($line)) { continue }
	
	$basePath = Join-Path "$($publishDir.FullName)\PSFramework" $line
	foreach ($entry in (Resolve-Path -Path $basePath))
	{
		$item = Get-Item $entry
		if ($item.PSIsContainer) { continue }
		if ($item.FullName -in $processed) { continue }
		$text += [System.IO.File]::ReadAllText($item.FullName)
		$processed += $item.FullName
	}
}
if ($text) { $text -join "`n`n" | Set-Content -Path "$($publishDir.FullName)\PSFramework\resourcesAfter.ps1" }

if (-not $SkipPublish)
{
	Write-Host "Publishing to gallery"
	# Publish to Gallery
	Publish-Module -Path "$($publishDir.FullName)\PSFramework" -NuGetApiKey $ApiKey -Force
}