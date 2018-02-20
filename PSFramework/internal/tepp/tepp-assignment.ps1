
# Configuration
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