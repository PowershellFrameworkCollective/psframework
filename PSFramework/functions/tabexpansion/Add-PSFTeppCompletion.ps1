function Add-PSFTeppCompletion {
	<#
	.SYNOPSIS
		Adds a completion result to a tab completion script.
		
	.DESCRIPTION
		Adds a completion result to a tab completion script.
		This allows specifically adding individual values to provide when completing, no matter the actual completion logic.
		Use Register-PSFTeppScriptblock to define a new completion scriptblock.
	
	.PARAMETER Name
		Name of the tab completion scriptblock to add to.
		Use Register-PSFTeppScriptblock to define a new completion scriptblock.
	
	.PARAMETER Options
		The completion objects to provide.
		Provide either a basic string or a hashtable with some key/value pairs:
		- Text: Mandatory. The text to complete.
		- ToolTip: A friendly text to provide some context when completing using CTRL+Space.
		- ListItemText: The text to show in the completion menu, but different from the actual text inserted.
		- ToolTipString: A localization key to resolve into the currently configured language for the ToolTip.
		- ListItemTextString: A localization key to resolve into the currently configured language for the ListItemText.
	
	.EXAMPLE
		PS C:\> Add-PSFTeppCompletion -Name 'Alcohol.Type' -Options Wine, Beer, Vodka

		Adds these options to the specified completion results: Wine, Beer, Vodka
		
	.EXAMPLE
		PS C:\> Add-PSFTeppCompletion -Name 'Alcohol.Type' -Options @{ Text = 'Mead'; ToolTip = 'Elixir of the angry gods' }

		Add a completion to the completer named "Alcohol.Type", offering the text "Mead" and explaining it with the specified tooltip.
	#>
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('PSFramework-tepp-scriptblockname')]
		[PsfValidateSet(TabCompletion = 'PSFramework-tepp-scriptblockname')]
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[object[]]
		$Options
	)
	process {
		$completionScript = [PSFramework.TabExpansion.TabExpansionHost]::Scripts[$Name]
		foreach ($option in $Options) {
			if ($option -is [string]) { $completionScript.AddTraining($option) }
			else { $completionScript.AddTraining(($option | ConvertTo-PSFHashtable)) }
		}
	}
}