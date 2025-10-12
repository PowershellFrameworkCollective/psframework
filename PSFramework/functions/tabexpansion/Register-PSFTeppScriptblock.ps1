function Register-PSFTeppScriptblock
{
    <#
        .SYNOPSIS
            Registers a scriptblock under name, to later be available for TabExpansion.
        
        .DESCRIPTION
            Registers a scriptblock under name, to later be available for TabExpansion.
	
			This system supports two separate types of input: Full or Simple.
	
			Simple:
			The scriptblock simply must return string values.
			PSFramework will then do the rest of the processing when the user asks for tab completion.
			This is the simple-most way to implement tab completion, for a full example, look at the first example in this help.
	
			Full:
			A full scriptblock implements all that is needed to provide Tab Expansion.
			For more details and guidance, see the following concept help:
				Get-Help about_psf_tabexpansion
        
        .PARAMETER ScriptBlock
            The scriptblock to register.
        
        .PARAMETER Name
            The name under which the scriptblock should be registered.
			It is recommended to prefix the name with the module (e.g.: mymodule.<name>), as names are shared across all implementing modules.
	
		.PARAMETER Mode
			Whether the script provided is a full or simple scriptblock.
			By default, this function automatically detects this, but just in case, you can override this detection.
	
		.PARAMETER CacheDuration
			How long a tab completion result is valid.
			By default, PSFramework tab completion will run the scriptblock on each call.
			This can be used together with a background refresh mechanism to offload the cost of expensive queries into the background.
			See Set-PSFTeppResult for details on how to refresh the cache.
	
		.PARAMETER Global
			Whether the scriptblock should be executed in the global context.
			This parameter is needed to reliably execute in background runspaces, but means no direct access to module content.

		.PARAMETER MaxResults
			The maximum number of results shown to the user.
			If more completions would be viable, only the first X are shown, as well as a message informaing about the truncation.

		.PARAMETER MatchAnywhere
			Match input against any part of the completion text, not just the beginning.

		.PARAMETER FuzzyMatch
			Apply FuzzyMatching to the legal completion text, not just direct word matching.

		.PARAMETER AlwaysQuote
			All completion results will be wrapped in quotes, not just the ones with a whitespace.

		.PARAMETER DontSort
			Completion results are no longer sorted alphabetically.

		.PARAMETER DontFilter
			Do not automatically filter by the words the user typed.
			This allows for the scriptblock to provide its own, more complex filtering.

		.PARAMETER AutoTraining
			Automatically train the tab completion by caching user inputs.
			Requires using Update-PSFTeppCompletion inside of the respective command, to automatically pick up new values.
	
		.EXAMPLE
			Register-PSFTeppScriptblock -Name "psalcohol-liquids" -ScriptBlock { "beer", "mead", "wine", "vodka", "whiskey", "rum" }
			Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name "psalcohol-liquids"
	
			In step one we set a list of questionable liquids as the list of available beverages for parameter 'Type' on the command 'Get-Alcohol'
        
        .EXAMPLE
            Register-PSFTeppScriptblock -ScriptBlock $scriptBlock -Name MyFirstTeppScriptBlock
    
            Stores the scriptblock stored in $scriptBlock under the name "MyFirstTeppScriptBlock"
	
		.EXAMPLE
			$scriptBlock = { (Get-ChildItem (Get-PSFConfigValue -FullName mymodule.path.scripts -Fallback "$env:USERPROFILE\Documents\WindowsPowerShell\Scripts")).FullName }
			Register-PSFTeppScriptblock -Name mymodule-scripts -ScriptBlock $scriptBlock -Mode Simple
	
			Stores a simple scriptblock that will return a list of strings under the name "mymodule-scripts".
			The system will wrap all the stuff around this that is necessary to provide Tab Expansion and filter out output that doesn't fit the user input so far.
    #>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFTeppScriptblock')]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$ScriptBlock,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[PSFramework.TabExpansion.TeppScriptMode]
		$Mode = "Auto",
		
		[PSFramework.Parameter.TimeSpanParameter]
		$CacheDuration = 0,

		[int]
		$MaxResults,
		
		[switch]
		$Global,

		[switch]
		$MatchAnywhere,

		[switch]
		$FuzzyMatch,

		[switch]
		$AlwaysQuote,

		[switch]
		$DontSort,

		[switch]
		$DontFilter,

		[switch]
		$AutoTraining
	)
	
	process
	{
		[PSFramework.TabExpansion.TabExpansionHost]::RegisterCompletion($Name, $ScriptBlock, $Mode, $CacheDuration, $Global)
		$scriptContainer = [PSFramework.TabExpansion.TabExpansionHost]::Scripts[$Name]
		if ($PSBoundParameters.Keys -contains 'MatchAnywhere') { $scriptContainer.MatchAnywhere = $MatchAnywhere }
		if ($PSBoundParameters.Keys -contains 'MaxResults') { $scriptContainer.MaxResults = $MaxResults }
		if ($PSBoundParameters.Keys -contains 'FuzzyMatch') { $scriptContainer.MatchAnywhere = $FuzzyMatch }
		if ($PSBoundParameters.Keys -contains 'AlwaysQuote') { $scriptContainer.MatchAnywhere = $AlwaysQuote }
		if ($PSBoundParameters.Keys -contains 'DontSort') { $scriptContainer.DontSort = $DontSort }
		if ($PSBoundParameters.Keys -contains 'DontFilter') { $scriptContainer.DoNotFilter = $DontFilter }
		if ($PSBoundParameters.Keys -contains 'AutoTraining') { $scriptContainer.AutoTraining = $AutoTraining }
	}
}
