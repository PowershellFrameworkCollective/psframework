# Load English Language Files
foreach ($item in (Resolve-Path "$script:ModuleRoot\en-us\*.psd1"))
{
	Import-LocalizedString -Path $item -Module PSFramework -Language 'en-US'
}

$script:strings = Get-PSFLocalizedString -Module PSFramework