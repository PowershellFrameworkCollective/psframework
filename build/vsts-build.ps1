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

Write-Host @"

# Listing arguments #
#-------------------#

"@

$args | Format-List | Out-Host

Write-Host "########################################################################################################" -ForegroundColor DarkGreen

Write-Host "Downloading from 'https://github.com/PowershellFrameworkCollective/psframework/raw/$($env:BUILD_SOURCEBRANCHNAME)/PSFramework/bin/PSFramework.dll'"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile("https://github.com/PowershellFrameworkCollective/psframework/raw/$($env:BUILD_SOURCEBRANCHNAME)/PSFramework/bin/PSFramework.dll","$((Get-Location).Path)\PSFramework.dll")
#Invoke-WebRequest -OutFile PSFramework.dll -Uri "https://github.com/PowershellFrameworkCollective/psframework/blob/$($env:BUILD_SOURCEBRANCHNAME)/PSFramework/bin/PSFramework.dll"

Write-Host "Downloaded file has $((Get-Item PSFramework.dll).Length) bytes"
Write-Host "Previous file has $((Get-Item PSFramework\bin\PSFramework.dll).Length) bytes"
$contentOnline = Get-Content PSFramework.dll -Encoding Byte
$contentBuild = Get-Content "PSFramework\bin\PSFramework.dll" -Encoding Byte

# Since VSTS Filehashes appear to be non-functional for this test, we'll have to do an old-fashioned content comparison
$test = $true
if ($contentOnline.Length -ne $contentBuild.Length) { $test = $false }
else
{
	foreach ($n in (1 .. $contentBuild.Length))
	{
		if ($contentOnline[$n - 1] -ne $contentBuild[$n - 1])
		{
			$test = $false
			break
		}
	}
}

if (-not $test)
{
	$branch = $env:BUILD_SOURCEBRANCHNAME
	Write-Host "Library should be updated"
	Remove-Item .\PSFramework.dll -Force
	git add .
	git commit -m "VSTS Library Compile"
	git http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push -u VSTS "https://github.com/PowershellFrameworkCollective/psframework.git" head:$branch 
}
else
{
	Write-Host "Library is up to date"
}