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

Write-Host "Downloading from 'https://github.com/PowershellFrameworkCollective/psframework/raw/$($env:BUILD_SOURCEBRANCHNAME)/PSFramework/bin/PSFramework.dll'"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile("https://github.com/PowershellFrameworkCollective/psframework/raw/$($env:BUILD_SOURCEBRANCHNAME)/PSFramework/bin/PSFramework.dll","$((Get-Location).Path)\PSFramework.dll")
#Invoke-WebRequest -OutFile PSFramework.dll -Uri "https://github.com/PowershellFrameworkCollective/psframework/blob/$($env:BUILD_SOURCEBRANCHNAME)/PSFramework/bin/PSFramework.dll"

Write-Host "Downloaded file has $((Get-Item PSFramework.dll).Length) bytes"
$hashOld = Get-FileHash PSFramework.dll
Write-Host "Previous file has $((Get-Item PSFramework\bin\PSFramework.dll).Length) bytes"
$hashNew = Get-FileHash "PSFramework\bin\PSFramework.dll"

$hashOld, $hashNew | Format-Table | Out-Host

if ($hashOld.Hash -ne $hashNew.Hash)
{
	Write-Host "Library should be updated"
}
else
{
	Write-Host "Library is up to date"
}