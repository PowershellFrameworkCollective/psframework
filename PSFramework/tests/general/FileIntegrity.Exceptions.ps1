# List of forbidden commands
$global:BannedCommands = @(
	'Write-Host',
	'Write-Verbose',
	'Write-Warning',
	'Write-Error',
	'Write-Output',
	'Write-Information'
)

# Contains list of exceptions for banned cmdlets
$global:MayContainCommand = @{
	"Write-Host"  = @('Write-PSFHostColor.ps1')
	"Write-Verbose" = @()
	"Write-Warning" = @()
	"Write-Error"  = @('Invoke-PSFCommand.ps1','Stop-PSFFunction.ps1')
	"Write-Output" = @()
	"Write-Information" = @()
}