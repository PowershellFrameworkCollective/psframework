$item = Get-Item "PSFramework\bin\PSFramework.dll"
$version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($item.FullName).FileVersion
$version | Export-Clixml ".\vsts-version.xml"