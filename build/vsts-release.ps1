[CmdletBinding()]
param (
	
)

# Step 1: Generate Module Content
$moduleVersion = (Import-PowerShellDataFile -Path "$PSScriptRoot\..\PSFramework\PSFramework.psd1").ModuleVersion
& "$PSScriptRoot\vsts-build.ps1" -SkipPublish

# Step 2: Zip Module Content
Compress-Archive -Path "$PSScriptRoot\..\publish\PSFramework\*" -DestinationPath "$PSScriptRoot\..\publish\PSFramework.zip" -Force

# Step 3: Create Release
$response = Invoke-RestMethod -Method POST -Uri 'https://api.github.com/repos/PowershellFrameworkCollective/PSFramework/releases' -Headers @{
	Authorization = "Bearer $env:GH_TOKEN"
	Accept = 'application/vnd.github+json'
	'X-GitHub-Api-Version' = '2022-11-28'
} -Body (@{
	tag_name = "v$moduleVersion"
	name = "v$moduleVersion"
	body = "Releasing v$moduleVersion of the PSFramework module."
	make_latest = 'true'
} | ConvertTo-Json -Depth 10 -Compress)

# Step 4: Upload ZIP as Release content

Invoke-RestMethod -Method POST -Uri "$($response.assets_url -replace 'api\.github\.com', 'uploads.github.com')?name=PSFramework.zip" -Headers @{
	Authorization = "Bearer $env:GH_TOKEN"
	Accept = 'application/vnd.github+json'
	'X-GitHub-Api-Version' = '2022-11-28'
	'Content-Type' = 'application/octet-stream'
} -InFile "$PSScriptRoot\..\publish\PSFramework.zip"
