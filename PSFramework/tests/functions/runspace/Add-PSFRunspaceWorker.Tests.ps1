Describe "Testing the command Add-PSFRunspaceWorker" -Tag "CI", "Pipeline", "Unit" {
	BeforeEach {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
		$null = New-PSFRunspaceDispatcher -Name "Test"
	}
	AfterAll {
		& (Get-Module PSFramework) { $script:runspaceDispatchers = @{ } }
	}
}

<#
$dis = New-PSFRunspaceDispatcher -Name "Test" -Force
$dis | Add-PSFRunspaceWorker -Name Gatherer -InQueue Input -OutQueue Processed -Count 5 -Variables @{ Multiplier = 5 } -ScriptBlock {
	param ($Value)
	Start-Sleep -Milliseconds 25
	$Multiplier * $Value
}
$dis | Add-PSFRunspaceWorker -Name Processor -InQueue Processed -OutQueue Done -Count 2 -Variables @{ Divisor = 10 } -Modules String -ScriptBlock {
	param ($Value)
	'# {0} | {1} -> {2} ({3})' -f $Value.Count, $Value, ($Value -join ", "), $Value.GetType().FullName
}
1..1000 | ForEach-Object { Write-PSFRunspaceQueue -Name Input -Value $_ -InputObject $dis }
$dis | Start-PSFRunspaceDispatcher

$dis | Get-PSFRunspaceWorker
#>