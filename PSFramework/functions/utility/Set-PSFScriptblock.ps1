function Set-PSFScriptblock
{
<#
	.SYNOPSIS
		Stores a scriptblock in the central scriptblock store.
	
	.DESCRIPTION
		Stores a scriptblock in the central scriptblock store.
		This store can be accessed using Get-PSFScriptblock.
		It is used to share scriptblocks outside of scope and runspace boundaries.
		Scriptblocks thus registered can be accessed by C#-based services, such as the PsfValidateScript attribute.
	
	.PARAMETER Name
		The name of the scriptblock.
		Must be unique, it is recommended to prefix the module name:
		<Module>.<Scriptblock>
	
	.PARAMETER Scriptblock
		The scriptcode to register
	
	.PARAMETER Global
		Whether the scriptblock should be invoked in the global context.
		If defined, accessing the scriptblock will automatically globalize it before returning it.
	
	.EXAMPLE
		PS C:\> Set-PSFScriptblock -Name 'MyModule.TestServer' -Scriptblock $Scriptblock
	
		Stores the scriptblock contained in $Scriptblock under the 'MyModule.TestServer' name.
	
	.NOTES
		Repeatedly registering the same scriptblock (e.g. in multi-runspace scenarios) is completely safe:
		- Access is threadsafe & Runspacesafe
		- Overwriting the scriptblock does not affect the statistics
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$Scriptblock,
		
		[switch]
		$Global
	)
	process
	{
		if ([PSFramework.Utility.UtilityHost]::ScriptBlocks.ContainsKey($Name))
		{
			[PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name].Scriptblock = $Scriptblock
			if ($Global.IsPresent) { [PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name].Global = $Global }
		}
		else
		{
			[PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name] = New-Object PSFramework.Utility.ScriptBlockItem($Name, $Scriptblock, $Global)
		}
	}
}