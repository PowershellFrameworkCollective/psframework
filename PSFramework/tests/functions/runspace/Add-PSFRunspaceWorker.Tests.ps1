﻿Describe "Testing the command Add-PSFRunspaceWorker" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
		$null = New-PSFRunspaceWorkflow -Name "Test"
	}
	AfterEach {
		Get-PSFRunspaceWorkflow | Remove-PSFRunspaceWorkflow
		& (Get-Module PSFramework) { $script:runspaceWorkflows = @{ } }
	}


}

return

# Case 1: Simple Handoff
$dis = New-PSFRunspaceWorkflow -Name "Test" -Force
$dis | Add-PSFRunspaceWorker -Name Gatherer -InQueue Input -OutQueue Processed -Count 5 -Variables @{ Multiplier = 5 } -ScriptBlock {
	param ($Value)
	Start-Sleep -Milliseconds 25
	$Value * $Multiplier
}
$dis | Add-PSFRunspaceWorker -Name Processor -InQueue Processed -OutQueue Done -Count 2 -Variables @{ Divisor = 10 } -Modules String -ScriptBlock {
	param ($Value)
	$Value / $Divisor
}
1..1000 | ForEach-Object { Write-PSFRunspaceQueue -Name Input -Value $_ -InputObject $dis }
$dis | Start-PSFRunspaceWorkflow

$dis | Get-PSFRunspaceWorker

$dis | Remove-PSFRunspaceWorkflow

# Case 2: Longrunning Generator & Passing in cool stuff
function Get-Data {
	[CmdletBinding()]
	param (
		[PSFramework.Parameter.TimeSpanParameter]
		$Duration,

		[PSFramework.Parameter.TimeSpanParameter]
		$Interval
	)

	$limit = (Get-Date).Add($Duration)
	while ($limit -gt (Get-Date)) {
		Get-Random -Minimum 10 -Maximum 99
		Start-Sleep -Duration $Interval
	}
}
$fun = Get-Command Get-Data
$dis2 = New-PSFRunspaceWorkflow -Name "Test2" -Force
$dis2 | Add-PSFRunspaceWorker -Name Generator -InQueue Input -OutQueue Data -Count 1 -Functions @{ $fun.Name = $fun.Definition } -ScriptBlock {
	Get-Data -Duration '10m' -Interval '1s' | ForEach-Object {
		Write-PSFRunspaceQueue -Name Data -Value $_ -InputObject $__PSF_Workflow
	}
}
$dis2 | Add-PSFRunspaceWorker -Name Converter -InQueue Data -OutQueue Done -Count 5 -VarPerRunspace @{ Multiplier = 2, 3, 4, 5, 6 } -ScriptBlock {
	param ($Value)

	[PSCustomObject]@{
		Value      = $Value
		Multiplier = $Multiplier
		Result     = $Value * $Multiplier
		Runspace   = [runspace]::DefaultRunspace.Name
	}
}
Write-PSFRunspaceQueue -Name Input -Value 42 -InputObject $dis2
$dis2 | Start-PSFRunspaceWorkflow

$dis2 | Get-PSFRunspaceWorker

$dis2 | Remove-PSFRunspaceWorkflow