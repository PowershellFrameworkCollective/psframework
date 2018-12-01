Import-LocalizedString -Path (Resolve-Path "$script:ModuleRoot\en-us\stringsAssembly.psd1") -Module PSFramework -Language 'en-US'


$script:strings = Get-PSFLocalizedString -Module PSFramework