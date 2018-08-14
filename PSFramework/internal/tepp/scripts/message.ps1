Register-PSFTeppScriptblock -Name 'PSFramework.Message.Module' -ScriptBlock {
	Get-PSFMessage | Select-Object -ExpandProperty ModuleName | Select-Object -Unique
}

Register-PSFTeppScriptblock -Name 'PSFramework.Message.Function' -ScriptBlock {
	Get-PSFMessage | Select-Object -ExpandProperty FunctionName | Select-Object -Unique
}

Register-PSFTeppScriptblock -Name 'PSFramework.Message.Tags' -ScriptBlock {
	Get-PSFMessage | Select-Object -ExpandProperty Tags | Remove-PSFNull -Enumerate | Select-Object -Unique
}

Register-PSFTeppScriptblock -Name 'PSFramework.Message.Runspace' -ScriptBlock {
	Get-PSFMessage | Select-Object -ExpandProperty Runspace | Select-Object -Unique
}

Register-PSFTeppScriptblock -Name 'PSFramework.Message.Level' -ScriptBlock {
	Get-PSFMessage | Select-Object -ExpandProperty Level | Select-Object -Unique
}