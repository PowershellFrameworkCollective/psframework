Register-PSFTeppScriptblock -Name 'PSFramework-dynamiccontentobject-name' -ScriptBlock {
	[PSFramework.Utility.DynamicContentObject]::List
} -Global