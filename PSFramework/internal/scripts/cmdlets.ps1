<#
Registers the cmdlets published by this module.
Necessary for full hybrid module support.
#>
$commonParam = @{
	HelpFile  = "$($PSModuleRoot)$($dc)en-us$($dc)PSFramework.dll-Help.xml"
	Module = $ExecutionContext.SessionState.Module
}

Import-PSFCmdlet @commonParam -Name Remove-PSFNull -Type ([PSFramework.Commands.RemovePSFNullCommand])
Import-PSFCmdlet @commonParam -Name Select-PSFObject -Type ([PSFramework.Commands.SelectPSFObjectCommand])
Import-PSFCmdlet @commonParam -Name Set-PSFConfig -Type ([PSFramework.Commands.SetPSFConfigCommand])
Import-PSFCmdlet @commonParam -Name Test-PSFShouldProcess -Type ([PSFramework.Commands.TestPSFShouldProcessCommand])
Import-PSFCmdlet @commonParam -Name Write-PSFMessage -Type ([PSFramework.Commands.WritePSFMessageCommand])