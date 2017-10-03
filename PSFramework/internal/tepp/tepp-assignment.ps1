
# Configuration
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter FullName -Name config-fullname
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter Module -Name config-module
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter Name -Name config-name

Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter FullName -Name config-fullname
Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter Module -Name config-module
Register-PSFTeppArgumentCompleter -Command Set-PSFConfig -Parameter Name -Name config-name

Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter FullName -Name config-fullname
Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter Module -Name config-module
Register-PSFTeppArgumentCompleter -Command Register-PSFConfig -Parameter Name -Name config-name

Register-PSFTeppArgumentCompleter -Command Get-PSFConfigValue -Parameter FullName -Name config-fullname