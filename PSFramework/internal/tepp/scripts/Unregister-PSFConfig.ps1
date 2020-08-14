Register-PSFTeppScriptblock -Name "PSFramework-Unregister-PSFConfig-FullName" -ScriptBlock {
	switch ("$($fakeBoundParameter.Scope)")
	{
		"UserDefault" { $path = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" }
		"UserMandatory" { $path = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced" }
		"SystemDefault" { $path = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" }
		"SystemMandatory" { $path = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced" }
		default { $path = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" }
	}
	
	if (Test-Path $path)
	{
		$properties = Get-ItemProperty -Path $path
		$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
		$properties.PSObject.Properties.Name | Where-Object { $_ -notin $common }
	}
} -Global

Register-PSFTeppScriptblock -Name "PSFramework-Unregister-PSFConfig-Module" -ScriptBlock {
	[PSFramework.Configuration.ConfigurationHost]::Configurations.Values.Module | Select-Object -Unique
} -Global