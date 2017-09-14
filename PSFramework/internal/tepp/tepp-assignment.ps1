
# Configuration
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter FullName -Name config-fullname
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter Module -Name config-module
Register-PSFTeppArgumentCompleter -Command Get-PSFConfig -Parameter Name -Name config-name

Register-PSFTeppArgumentCompleter -Command Get-PSFConfigValue -Parameter FullName -Name config-fullname