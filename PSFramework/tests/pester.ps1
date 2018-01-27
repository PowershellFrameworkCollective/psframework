param (
	[ValidateSet('None', 'Default', 'Passed', 'Failed', 'Pending', 'Skipped', 'Inconclusive', 'Describe', 'Context', 'Summary', 'Header', 'Fails', 'All')]
	[string]
	$Show = "None",
	
	[ValidateSet('Everything', 'Functions', 'General')]
	[string]
	$Run = "Everything",
	
	[string]
	$Filter = "*.Tests.ps1"
)

Write-Host "Starting Tests" -ForegroundColor Green
Write-Host "Installing Pester" -ForegroundColor Cyan
if ($env:BUILD_BUILDURI -like "vstfs*") { Install-Module Pester -Force -SkipPublisherCheck }

Write-Host "Importing Module" -ForegroundColor Cyan

Remove-Module PSFramework -ErrorAction Ignore
Import-Module "$PSScriptRoot\..\PSFramework.psd1"
Import-Module "$PSScriptRoot\..\PSFramework.psm1" -Force

$totalFailed = 0
$totalRun = 0

$testresults = @()

if ($Run -match "Everything|General")
{
	Write-PSFMessage -Level Important -Message "Modules imported, proceeding with general tests"
	foreach ($file in (Get-ChildItem "$PSScriptRoot\general" -Filter $Filter))
	{
		Write-PSFMessage -Level Significant -Message "  Executing <c='em'>$($file.Name)</c>"
		$results = Invoke-Pester -Script $file.FullName -Show $Show -PassThru
		foreach ($result in $results)
		{
			$totalRun += $result.TotalCount
			$totalFailed += $result.FailedCount
			$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
				$name = $_.Name
				$testresults += [pscustomobject]@{
					Describe   = $_.Describe
					Context    = $_.Context
					Name	   = "It $name"
					Result	   = $_.Result
					Message    = $_.FailureMessage
				}
			}
		}
	}
}

if ($Run -match "Everything|Functions")
{
	Write-PSFMessage -Level Important -Message "Proceeding with individual tests"
	foreach ($file in (Get-ChildItem "$PSScriptRoot\functions" -Recurse -File -Filter $Filter))
	{
		Write-PSFMessage -Level Significant -Message "  Executing $($file.Name)"
		$results = Invoke-Pester -Script $file.FullName -Show $Show -PassThru
		foreach ($result in $results)
		{
			$totalRun += $result.TotalCount
			$totalFailed += $result.FailedCount
			$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
				$name = $_.Name
				$testresults += [pscustomobject]@{
					Describe    = $_.Describe
					Context	    = $_.Context
					Name	    = "It $name"
					Result	    = $_.Result
					Message	    = $_.FailureMessage
				}
			}
		}
	}
}

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

if ($totalFailed -eq 0) { Write-PSFMessage -Level Critical -Message "All <c='em'>$totalRun</c> tests executed without a single failure!" }
else { Write-PSFMessage -Level Critical -Message "<c='em'>$totalFailed tests</c> out of <c='sub'>$totalRun</c> tests failed!" }

if ($totalFailed -gt 0)
{
	throw "$totalFailed / $totalRun tests failed!"
}