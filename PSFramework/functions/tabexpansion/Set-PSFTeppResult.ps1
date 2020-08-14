function Set-PSFTeppResult
{
<#
	.SYNOPSIS
		Refreshes the tab completion value cache.
	
	.DESCRIPTION
		Refreshes the tab completion value cache for the specified completion scriptblock.
	
		Tab Completion scriptblocks can be configured to retrieve values from a dedicated cache.
		This allows seamless background refreshes of completion data and eliminates all waits for the user.
	
	.PARAMETER TabCompletion
		The name of the completion script to set the last results for.
	
	.PARAMETER Value
		The values to set.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Set-PSFTeppResult -TabCompletion 'MyModule.Computer' -Value (Get-ADComputer -Filter *).Name
	
		Stores the names of all computers in AD into the tab completion cache of the completion scriptblock 'MyModule.Computer'
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFTeppResult')]
	param (
		[Parameter(Mandatory = $true)]
		[PSFramework.Validation.PsfValidateSetAttribute(ScriptBlock = { [PSFramework.TabExpansion.TabExpansionHost]::Scripts.Keys } )]
		[string]
		$TabCompletion,
		
		[Parameter(Mandatory = $true)]
		[AllowEmptyCollection()]
		[string[]]
		$Value
	)
	
	process
	{
		if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $TabCompletion -ActionString 'Set-PSFTeppResult.UpdateValue')
		{
			[PSFramework.TabExpansion.TabExpansionHost]::Scripts[$TabCompletion].LastResult = $Value
			[PSFramework.TabExpansion.TabExpansionHost]::Scripts[$TabCompletion].LastExecution = ([System.DateTime]::Now)
		}
	}
}