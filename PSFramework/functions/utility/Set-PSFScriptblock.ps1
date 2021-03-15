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
	
	.PARAMETER Local
		Whether the scriptblock should be local to the current runspace.
		If defined, each runspace must define its own instance of the scriptblock to use it.

	.PARAMETER Tag
		A list of tags to apply to a scriptblock. Used for easier filtering.

	.PARAMETER Description
		A description for a scriptblock. Used for easier filtering and in lieu of documentation.
	
	.EXAMPLE
		PS C:\> Set-PSFScriptblock -Name 'MyModule.TestServer' -Scriptblock $Scriptblock
	
		Stores the scriptblock contained in $Scriptblock under the 'MyModule.TestServer' name.
	
	.EXAMPLE
		PS C:\> Set-PSFScriptblock -Name 'MyModule.TestServer' -Scriptblock $Scriptblock -Tag Awesome, BestCodeEver -Description 'This scriptblock is the only one you need'
	
		Stores the scriptblock contained in $Scriptblock under the 'MyModule.TestServer' name.
		Applies the tags 'Awesome' and 'BestCodeEver', as well as a descriptive text.
	
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
		$Global,
		
		[switch]
		$Local,
		
		[AllowEmptyCollection()]
		[string[]]
		$Tag,
		
		[AllowEmptyString()]
		[string]
		$Description
	)
	process
	{
		if ([PSFramework.Utility.UtilityHost]::ScriptBlocks.ContainsKey($Name))
		{
			[PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name].Scriptblock = $Scriptblock
			if (Test-PSFParameterBinding -ParameterName Global -BoundParameters $PSBoundParameters) { [PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name].Global = $Global }
			if (Test-PSFParameterBinding -ParameterName Local -BoundParameters $PSBoundParameters) { [PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name].Local = $Local }
			if ($null -ne $Tag) { [PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name].Tag = $Tag }
			if (Test-PSFParameterBinding -ParameterName Description -BoundParameters $PSBoundParameters) { [PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name].Description = $Description }
		}
		else
		{
			[PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name] = New-Object PSFramework.Utility.ScriptBlockItem($Name, $Scriptblock, $Global, $Local, $Tag, $Description)
		}
	}
}
