﻿@{
	'Import-PSFPowerShellDataFile.Error.NoHashtable'    = 'File contains no hashtable: {0}' # $LiteralPath
	'Import-PSFPowerShellDataFile.Error.Syntax'         = 'File has an invalid PowerShell syntax: {0}' # $LiteralPath
	'Import-PSFPowerShellDataFile.Error.Unsafe'         = 'File is not safe to execute: {0}' # $LiteralPath

	'New-PSFSupportPackage.Error.PathNotFound' = 'Path not found: "$Path". Ensure the path exists or use -Force to create it.' # $Path
	'New-PSFSupportPackage.Header'                      = @"
Gathering information...
Will write the final output to: {0}
{1}
Be aware that this package contains a lot of information including your input history in the console.
Please make sure no sensitive data (such as passwords) can be caught this way.

Ideally start a new console, perform the minimal steps required to reproduce the issue, then run this command.
This will make it easier for us to troubleshoot and you won't be sending us the keys to your castle.
"@ # $filePathZip, (Get-PSFConfigValue -FullName 'psframework.supportpackage.contactmessage' -Fallback '')
	'New-PSFSupportPackage.Messages'                    = "Collecting PSFramework logged messages (Get-PSFMessage)" # 
	'New-PSFSupportPackage.MsgErrors'                   = "Collecting PSFramework logged errors (Get-PSFMessage -Errors)" # 
	'New-PSFSupportPackage.ConsoleBuffer'               = "Trying to collect copy of console buffer (what you can see on your console)" # 
	'New-PSFSupportPackage.OperatingSystem'             = "Collecting Operating System information (Win32_OperatingSystem)" # 
	'New-PSFSupportPackage.CPU'                         = "Collecting CPU information ({0})" # 
	'New-PSFSupportPackage.RAM'                         = "Collecting Ram information ({0})" # 
	'New-PSFSupportPackage.PSVersion'                   = "Collecting PowerShell & .NET Version (`$PSVersionTable)" # 
	'New-PSFSupportPackage.History'                     = "Collecting Input history (Get-History)" # 
	'New-PSFSupportPackage.Modules'                     = "Collecting list of loaded modules (Get-Module)" # 
	'New-PSFSupportPackage.Snapins'                     = "Collecting list of loaded snapins (Get-PSSnapin)" # 
	'New-PSFSupportPackage.Assemblies'                  = "Collecting list of loaded assemblies (Name, Version, and Location)" # 
	'New-PSFSupportPackage.Variables'                   = "Adding variables specified for export: {0}" # ($Variables -join ", ")
	'New-PSFSupportPackage.PSErrors'                    = "Adding content of `$Error" # 
	'New-PSFSupportPackage.DbaTools.Messages'           = "Collecting dbatools logged messages (Get-DbatoolsLog)" # 
	'New-PSFSupportPackage.DbaTools.Errors'             = "Collecting dbatools logged errors (Get-DbatoolsLog -Errors)" # 
	'New-PSFSupportPackage.Export.Failed'               = "Failed to export dump to file!" # 
	'New-PSFSupportPackage.Extension.Collecting'        = 'Collecting Extension Debugging Data: {0}' # $pair.Key
	'New-PSFSupportPackage.Extension.Collecting.Failed' = 'Failed to collect Extension Debugging Data: {0}' # $pair.Key
	'New-PSFSupportPackage.ZipCompression.Failed'       = "Failed to pack dump-file into a zip archive. Please do so manually before submitting the results as the unpacked xml file will be rather large." # 

	'New-PSFThrottle.Error.InvalidLimit'                = 'Invalid throttle limit: {0} / {1}' # $pair.Key, $pair.Value
	
	'Resolve-PSFItem.BadPath'                           = 'Path could not be resolved: {0}' # $badPath
	'Resolve-PSFItem.BadPaths'                          = 'Paths could not be resolved: {0}' # ($badPaths -join ', ')
	'Resolve-PSFItem.Path.Found'                        = 'Found {1} items under {0}' # $entry, @($results).Count
	'Resolve-PSFItem.Path.Summary'                      = 'Searched {0} paths, finding {1} items. {2} paths could not be resolved.' # (@($Path).Count + @($LiteralPath).Count), $foundItems.Count, $badPaths.Count

	'Resolve-PSFPath.Path.ParentExistsNot'              = "Failed to resolve path" # 
	'Resolve-PSFPath.Path.MultipleParents'              = "Could not resolve to only a single parent path!" # 
	'Resolve-PSFPath.Path.WrongProvider'                = "Resolved provider is {0} when it should be {1}" # $parentPath.Provider.Name, $Provider
	'Resolve-PSFPath.Path.ExistsNot'                    = "Failed to resolve path" # 
	'Resolve-PSFPath.Path.MultipleItems'                = "Could not resolve to only a single path!" # 
}