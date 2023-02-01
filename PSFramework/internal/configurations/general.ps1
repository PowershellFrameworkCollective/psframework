# Unattended mode, so there is a central flag scripts & modules can detect
Set-PSFConfig -Module PSFramework -Name 'System.Unattended' -Value $false -Initialize -Validation "bool" -Handler { [PSFramework.PSFCore.PSFCoreHost]::Unattended = $args[0] } -Description "Central setting, showing whether the current execution is unattended or not. This allows scripts/modules to react to whether there is a user at the controls or not."
Set-PSFConfig -Module PSFramework -Name 'System.DefaultRepository' -Value 'PSGallery' -Initialize -Validation string -Description 'The default repository to install modules from. Respected by some logging providers and anybody else chosing to respect this setting.'

Set-PSFConfig -Module PSFramework -Name 'SupportPackage.ContactMessage' -Value ' ' -Initialize -Validation 'string' -Description 'Message shown when using New-PSFSUpportPackage. This allows an organization to tie information on how to submit a support package into the command that generates it'

# Encoding Settings
Set-PSFConfig -Module PSFramework -Name 'Text.Encoding.FullTabCompletion' -Value $false -Initialize -Validation 'bool' -Description 'Whether all encodings should be part of the tab completion for encodings. By default, only a manageable subset is shown.'
Set-PSFConfig -Module PSFramework -Name 'Text.Encoding.DefaultWrite' -Value 'utf-8' -Initialize -Validation 'string' -Description 'The default encoding to use when writing to file. Only applied by implementing commands.'
Set-PSFConfig -Module PSFramework -Name 'Text.Encoding.DefaultRead' -Value 'utf-8' -Initialize -Validation 'string' -Description 'The default encoding to use when reading from file. Only applied by implementing commands.'

# Localization Stuff
Set-PSFConfig -Module PSFramework -Name 'Localization.Language' -Value ([System.Globalization.CultureInfo]::CurrentUICulture.Name) -Initialize -Handler { [PSFramework.Localization.LocalizationHost]::Language = $args[0] } -Validation 'languagecode' -Description 'The language the current PowerShell session is operating under'
Set-PSFConfig -Module PSFramework -Name 'Localization.LoggingLanguage' -Value 'en-US' -Initialize -Handler { [PSFramework.Localization.LocalizationHost]::LoggingLanguage = $args[0] } -Validation 'languagecode' -Description 'The language the current PowerShell session is operating under'