param (
	$Enable
)

if (-not $Enable) { return }


Write-Host "PowerShell Data" -ForegroundColor Green
$PSVersionTable | Out-String | Write-Host

Write-Host ""
Write-Host "Modules Available:" -ForegroundColor Green
Get-Module -ListAvailable | Out-String | Write-Host

Write-Host ""
Write-Host "Variables Available" -ForegroundColor Green
Get-Variable | Out-String | Write-Host

Write-Host ""
Write-Host "Environment Variables" -ForegroundColor Green
Get-ChildItem env: | Out-String | Write-Host