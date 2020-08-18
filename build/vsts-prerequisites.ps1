Write-Host "Installing latest PackageManagement" -ForegroundColor Cyan
Start-Job { Install-Module PackageManagement -Force -SkipPublisherCheck } | Wait-Job
Write-Host "Installing latest PowerShellGet" -ForegroundColor Cyan
Start-Job { Install-Module PowerShellGet -Force -SkipPublisherCheck } | Wait-Job

Write-Host "Installing Pester" -ForegroundColor Cyan
Install-Module Pester -Force -SkipPublisherCheck
Write-Host "Installing PSScriptAnalyzer" -ForegroundColor Cyan
Install-Module PSScriptAnalyzer -Force -SkipPublisherCheck
Write-Host "Installing latest PlatyPS" -ForegroundColor Cyan
Install-Module PlatyPS -Force -SkipPublisherCheck
Write-Host "Installing latest PSModuleDevelopment" -ForegroundColor Cyan
Install-Module PSModuleDevelopment -Force -SkipPublisherCheck