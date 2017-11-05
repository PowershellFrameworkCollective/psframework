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