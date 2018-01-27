# List of forbidden commands
$global:BannedCommands = @(
	'Write-Host',
	'Write-Verbose',
	'Write-Warning',
	'Write-Error',
	'Write-Output',
	'Write-Information',
	'Write-Debug'
)

# Contains list of exceptions for banned cmdlets
$global:MayContainCommand = @{
	"Write-Host"  = @('Write-PSFHostColor.ps1','Write-PSFMessage.ps1')
	"Write-Verbose" = @('Write-PSFMessage.ps1')
	"Write-Warning" = @('Write-PSFMessage.ps1')
	"Write-Error"  = @('Write-PSFMessage.ps1','Stop-PSFFunction.ps1')
	"Write-Output" = @()
	"Write-Information" = @()
	"Write-Debug" = @()
}