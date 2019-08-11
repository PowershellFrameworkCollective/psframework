Import-PSFLocalizedString -Path "$script:ModuleRoot\en-us\*.psd1" -Module PSFramework -Language 'en-US'

$script:strings = Get-PSFLocalizedString -Module PSFramework