function Remove-PSFTeppCompletion {
	<#
	.SYNOPSIS
		Removes a previously added completion result from a tab completion script.
		
	.DESCRIPTION
		Removes a previously added completion result from a tab completion script.
		These can be added using Add-PSFTeppCompletion or trained using Import-PSFTeppCompletion.
		This command has no effect on automatically calculated tab completions!
	
	.PARAMETER Name
		Name of the tab completion scriptblock to remove from.
		Use Register-PSFTeppScriptblock to define a new completion scriptblock.
	
	.PARAMETER Options
		The completion options to remove.
		Must be either the string value of the completion or a hashtable with the "Text" key containing the completion value.
	
	.EXAMPLE
		PS C:\> Remove-PSFTeppCompletion -Name 'Alcohol.Type' -Options 'Mojito', 'Caipirinha'

		Removes the two listed drinks from the list of legal completions.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('PSFramework-tepp-scriptblockname')]
		[PsfValidateSet(TabCompletion = 'PSFramework-tepp-scriptblockname')]
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('Completion')]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[object[]]
		$Options
	)
	
	process {
		$completionScript = [PSFramework.TabExpansion.TabExpansionHost]::Scripts[$Name]
		foreach ($option in $Options) {
			if ($option -is [string]) { $completionScript.RemoveTraining($option) }
			else { $completionScript.RemoveTraining($option.Text) }
		}
	}
}