Write-Host "Starting Tests" -ForegroundColor Green
Write-Host "Installing Pester" -ForegroundColor Cyan
Install-Module Pester -Force

Write-Host "Importing Module" -ForegroundColor Cyan

Remove-Module PSFramework -ErrorAction Ignore
Import-Module "$PSScriptRoot\..\PSFramework.psd1"
Import-Module "$PSScriptRoot\..\PSFramework.psm1" -Force

$totalFailed = 0
$totalRun = 0

Write-PSFMessage -Level Important -Message "Modules imported, proceeding with general tests"
foreach ($file in (Get-ChildItem "$PSScriptRoot\general" -Filter "*.Tests.ps1"))
{
	Write-PSFMessage -Level Significant -Message "  Executing <c='em'>$($file.Name)</c>"
	$results = Invoke-Pester -Script $file.FullName -Show None -PassThru
	foreach ($result in $results)
	{
		$totalRun += $result.TotalCount
		$totalFailed += $result.FailedCount
		$result.TestResult | Where-Object { -not $_.Passed }
	}
}

Write-PSFMessage -Level Important -Message "Proceeding with individual tests"
foreach ($file in (Get-ChildItem "$PSScriptRoot\functions" -Recurse -File -Filter "*Tests..ps1"))
{
	Write-PSFMessage -Level Significant -Message "  Executing $($file.Name)"
	$results = Invoke-Pester -Script $file.FullName -Show None -PassThru
	foreach ($result in $results)
	{
		$totalRun += $result.TotalCount
		$totalFailed += $result.FailedCount
		$result.TestResult | Where-Object { -not $_.Passed }
	}
}

if ($totalFailed -eq 0) { Write-PSFMessage -Level Critical -Message "All $totalRun tests executed without a single failure!" }
else { Write-PSFMessage -Level Critical -Message "<c='red'>$totalFailed tests</c> out of <c='sub'>$totalRun</c> tests failed!" }

if ($totalFailed -gt 0)
{
	throw "$totalFailed / $totalRun tests failed!"
}