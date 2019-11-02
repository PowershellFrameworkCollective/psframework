param (
	$TestGeneral = $true,
	
	$TestFunctions = $true,
	
	[ValidateSet('None', 'Default', 'Passed', 'Failed', 'Pending', 'Skipped', 'Inconclusive', 'Describe', 'Context', 'Summary', 'Header', 'Fails', 'All')]
	$Show = "None",
	
	$Include = "*",
	
	$Exclude = ""
)

Write-Host "Starting Tests"

Write-Host "Importing Module"

Remove-Module PSFramework -ErrorAction Ignore
Import-Module "$PSScriptRoot\..\PSFramework.psd1"
Import-Module "$PSScriptRoot\..\PSFramework.psm1" -Force

Write-PSFMessage -Level Important -Message "Creating test result folder"
$null = New-Item -Path "$PSScriptRoot\..\.." -Name TestResults -ItemType Directory -Force

$totalFailed = 0
$totalRun = 0

$testresults = @()

#region Load Extensions
foreach ($file in (Get-ChildItem "$PSScriptRoot\extensions" -Filter "*.ps1"))
{
	. $file.FullName
}
#endregion Load Extensions

#region Run General Tests
if ($TestGeneral)
{
	Write-PSFMessage -Level Important -Message "Modules imported, proceeding with general tests"
	foreach ($file in (Get-ChildItem "$PSScriptRoot\general" -Filter "*.Tests.ps1"))
	{
		Write-PSFMessage -Level Significant -Message "  Executing <c='em'>$($file.Name)</c>"
		$TestOuputFile = Join-Path "$PSScriptRoot\..\..\TestResults" "TEST-$($file.BaseName).xml"
		$results = Invoke-Pester -Script $file.FullName -Show $Show -PassThru -OutputFile $TestOuputFile -OutputFormat NUnitXml
		foreach ($result in $results)
		{
			$totalRun += $result.TotalCount
			$totalFailed += $result.FailedCount
			$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
				$name = $_.Name
				$testresults += [pscustomobject]@{
					Describe = $_.Describe
					Context  = $_.Context
					Name	 = "It $name"
					Result   = $_.Result
					Message  = $_.FailureMessage
				}
			}
		}
	}
}
#endregion Run General Tests

#region Test Commands
if ($TestFunctions)
{
Write-PSFMessage -Level Important -Message "Proceeding with individual tests"
	foreach ($folder in (Get-ChildItem "$PSScriptRoot\functions"))
	{
		if (-not $folder.PSIsContainer) { continue }
		Write-PSFMessage -Level Significant -Message "  Processing Component: <c='sub'>$($folder.Name)</c>"
		
		foreach ($file in (Get-ChildItem $folder.FullName -Recurse -File -Filter "*Tests.ps1"))
		{
			if ($file.Name -notlike $Include) { continue }
			if ($file.Name -like $Exclude) { continue }
			
			Write-PSFMessage -Level Significant -Message "    Executing <c='em'>$($file.Name)</c>"
			$TestOuputFile = Join-Path "$PSScriptRoot\..\..\TestResults" "TEST-$($file.BaseName).xml"
			$results = Invoke-Pester -Script $file.FullName -Show $Show -PassThru -OutputFile $TestOuputFile -OutputFormat NUnitXml
			foreach ($result in $results)
			{
				$totalRun += $result.TotalCount
				$totalFailed += $result.FailedCount
				$result.TestResult | Where-Object { -not $_.Passed } | ForEach-Object {
					$name = $_.Name
					$testresults += [pscustomobject]@{
						Describe = $_.Describe
						Context  = $_.Context
						Name	 = "It $name"
						Result   = $_.Result
						Message  = $_.FailureMessage
					}
				}
			}
		}
	}
}
#endregion Test Commands

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

if ($totalFailed -eq 0) { Write-PSFMessage -Level Critical -Message "All <c='em'>$totalRun</c> tests executed without a single failure!" }
else { Write-PSFMessage -Level Critical -Message "<c='em'>$totalFailed tests</c> out of <c='sub'>$totalRun</c> tests failed!" }

if ($totalFailed -gt 0)
{
	throw "$totalFailed / $totalRun tests failed!"
}