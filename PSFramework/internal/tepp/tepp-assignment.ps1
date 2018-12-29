#region Configuration
Register-PSFTeppArgumentCompleter -Command Export-PSFConfig -Parameter FullName -Name 'PSFramework-config-fullname'
Register-PSFTeppArgumentCompleter -Command Export-PSFConfig -Parameter Module -Name 'PSFramework-config-module'
Register-PSFTeppArgumentCompleter -Command Export-PSFConfig -Parameter Name -Name 'PSFramework-config-name'

Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter FullName -Name 'PSFramework-config-fullname'
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter Module -Name 'PSFramework-config-module'
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter Name -Name 'PSFramework-config-name'

Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter FullName -Name 'PSFramework-config-fullname'
Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter Module -Name 'PSFramework-config-module'
Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter Name -Name 'PSFramework-config-name'
Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter Validation -Name 'PSFramework-config-validation'

Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter FullName -Name 'PSFramework-config-fullname'
Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter Module -Name 'PSFramework-config-module'
Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter Name -Name 'PSFramework-config-name'

Register-PSFTeppArgumentCompleter -Command Get-PSFConfigValue -Parameter FullName -Name 'PSFramework-config-fullname'

Register-PSFTeppArgumentCompleter -Command Unregister-PSFConfig -Parameter FullName -Name 'PSFramework-Unregister-PSFConfig-FullName'
Register-PSFTeppArgumentCompleter -Command Unregister-PSFConfig -Parameter Module -Name 'PSFramework-Unregister-PSFConfig-Module'
#endregion Configuration

#region License
Register-PSFTeppArgumentCompleter -Command Get-PSFLicense -Parameter Filter -Name 'PSFramework-license-name'
#endregion License

#region Localization
Register-PSFTeppArgumentCompleter -Command Import-PSFLocalizedString -Parameter Language -Name 'PSFramework-LanguageNames'
Register-PSFTeppArgumentCompleter -Command Get-PSFLocalizedString -Parameter Module -Name 'PSFramework-LocalizedStrings-Modules'
Register-PSFTeppArgumentCompleter -Command Get-PSFLocalizedString -Parameter Name -Name 'PSFramework-LocalizedStrings-Names'
#endregion Localization

#region Logging
Register-PSFTeppArgumentCompleter -Command Get-PSFLoggingProvider -Parameter Name -Name 'PSFramework-logging-provider'
Register-PSFTeppArgumentCompleter -Command Install-PSFLoggingProvider -Parameter Name -Name 'PSFramework-logging-provider'
Register-PSFTeppArgumentCompleter -Command Set-PSFLoggingProvider -Parameter Name -Name 'PSFramework-logging-provider'
#endregion Logging

#region Message
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter ModuleName -Name 'PSFramework.Message.Module'
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter FunctionName -Name 'PSFramework.Message.Function'
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter Tag -Name 'PSFramework.Message.Tags'
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter Runspace -Name 'PSFramework.Message.Runspace'
Register-PSFTeppArgumentCompleter -Command Get-PSFMessage -Parameter Level -Name 'PSFramework.Message.Level'
#endregion Message

#region Runspace
Register-PSFTeppArgumentCompleter -Command Get-PSFRunspace -Parameter Name -Name 'PSFramework-runspace-name'
Register-PSFTeppArgumentCompleter -Command Register-PSFRunspace -Parameter Name -Name 'PSFramework-runspace-name'
Register-PSFTeppArgumentCompleter -Command Stop-PSFRunspace -Parameter Name -Name 'PSFramework-runspace-name'
Register-PSFTeppArgumentCompleter -Command Start-PSFRunspace -Parameter Name -Name 'PSFramework-runspace-name'

Register-PSFTeppArgumentCompleter -Command Get-PSFDynamicContentObject -Parameter Name -Name 'PSFramework-dynamiccontentobject-name'
Register-PSFTeppArgumentCompleter -Command Set-PSFDynamicContentObject -Parameter Name -Name 'PSFramework-dynamiccontentobject-name'
#endregion Runspace

#region Serialization
Register-PSFTeppArgumentCompleter -Command Export-PSFClixml -Parameter Encoding -Name 'PSFramework-Encoding'
Register-PSFTeppArgumentCompleter -Command Import-PSFClixml -Parameter Encoding -Name 'PSFramework-Encoding'
#endregion Serialization

#region Tab Completion
Register-PSFTeppArgumentCompleter -Command Set-PSFTeppResult -Parameter TabCompletion -Name 'PSFramework-tepp-scriptblockname'
#endregion Tab Completion

#region Utility
Register-PSFTeppArgumentCompleter -Command Resolve-PSFPath -Parameter Provider -Name 'PSFramework-utility-psprovider'
#endregion Utility