<#
Registers the cmdlets published by this module.
Necessary for full hybrid module support.
#>
$commonParam = @{
	HelpFile  = (Resolve-Path "$($script:ModuleRoot)\en-us\PSFramework.dll-Help.xml")
	Module = $ExecutionContext.SessionState.Module
}

Import-PSFCmdlet @commonParam -Name ConvertTo-PSFHashtable -Type ([PSFramework.Commands.ConvertToPSFHashtableCommand])
Import-PSFCmdlet @commonParam -Name Invoke-PSFCallback -Type ([PSFramework.Commands.InvokePSFCallbackCommand])
Import-PSFCmdlet @commonParam -Name Invoke-PSFProtectedCommand -Type ([PSFramework.Commands.InvokePSFProtectedCommand])
Import-PSFCmdlet @commonParam -Name Remove-PSFNull -Type ([PSFramework.Commands.RemovePSFNullCommand])
Import-PSFCmdlet @commonParam -Name Select-PSFObject -Type ([PSFramework.Commands.SelectPSFObjectCommand])
Import-PSFCmdlet @commonParam -Name Set-PSFObjectOrder -Type ([PSFramework.Commands.SortPSFObjectCommand])
Import-PSFCmdlet @commonParam -Name Set-PSFConfig -Type ([PSFramework.Commands.SetPSFConfigCommand])
Import-PSFCmdlet @commonParam -Name Test-PSFShouldProcess -Type ([PSFramework.Commands.TestPSFShouldProcessCommand])
Import-PSFCmdlet @commonParam -Name Write-PSFMessage -Type ([PSFramework.Commands.WritePSFMessageCommand])

Set-Alias -Name Sort-PSFObject -Value Set-PSFObjectOrder -Force -ErrorAction SilentlyContinue