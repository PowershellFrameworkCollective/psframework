Write-Host "Current Path : $((Get-Location).Path)" 

Write-Host @"
# Listing local variables #
#-------------------------#

"@

Get-Variable | Format-Table Name, @{
	n   = "Type"; e = {
		if ($_.Value -eq $null) { "<Null>" }
		else { $_.Value.GetType().FullName }
	}
}, Value | Out-String | Out-Host

Write-Host @"

# Listing environment variables #
#-------------------------------#

"@

Get-ChildItem "env:" | Out-Host

Write-Host "########################################################################################################" -ForegroundColor DarkGreen

Invoke-WebRequest -OutFile PSFramework.dll -Uri "https://github.com/PowershellFrameworkCollective/psframework/blob/$($env:BUILD_SOURCEBRANCHNAME)/PSFramework/bin/PSFramework.dll"

$hashOld = Get-FileHash PSFramework.dll
$hashNew = Get-FileHash "PSFramework\bin\PSFramework.dll"

if ($hashOld.Hash -ne $hashNew.Hash)
{
	Write-Host "Library should be updated"
}
else
{
	Write-Host "Library is up to date"
}