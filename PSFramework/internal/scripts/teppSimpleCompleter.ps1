[PSFramework.TabExpansion.TabExpansionHost]::SimpleCompletionScript = {
	param (
		$commandName,
		
		$parameterName,
		
		$wordToComplete,
		
		$commandAst,
		
		$fakeBoundParameter
	)

	function New-PSFTeppCompletionResult {
		<#
        .SYNOPSIS
            Generates a completion result for psframework internal tab completion.
        
        .DESCRIPTION
            Generates a completion result for psframework internal tab completion.
        
        .PARAMETER CompletionText
            The text to propose.
        
        .PARAMETER ToolTip
            The tooltip to show in tooltip-aware hosts (ISE, mostly)
        
        .PARAMETER ListItemText
            ???
        
        .PARAMETER CompletionResultType
            The type of object that is being completed.
            By default it generates one of type paramter value.
        
        .PARAMETER NoQuotes
            Whether to put the result in quotes or not.
        
        .EXAMPLE
            New-PSFTeppCompletionResult -CompletionText 'master' -ToolTip 'master'
    
            Returns a CompletionResult with the text and tooltip 'master'
    #>
		param (
			[Parameter(Position = 0, ValueFromPipelineByPropertyName = $true, Mandatory = $true, ValueFromPipeline = $true)]
			[ValidateNotNullOrEmpty()]
			[string]
			$CompletionText,
		
			[Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
			[string]
			$ToolTip,
		
			[Parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
			[string]
			$ListItemText,
		
			[System.Management.Automation.CompletionResultType]
			$CompletionResultType = [System.Management.Automation.CompletionResultType]::ParameterValue,
		
			[switch]
			$NoQuotes
		)
	
		process {
			$toolTipToUse = if ($ToolTip -eq '') { $CompletionText }
			else { $ToolTip }
			$listItemToUse = if ($ListItemText -eq '') { $CompletionText }
			else { $ListItemText }
		
			# If the caller explicitly requests that quotes
			# not be included, via the -NoQuotes parameter,
			# then skip adding quotes.
		
			if ($CompletionResultType -eq [System.Management.Automation.CompletionResultType]::ParameterValue -and -not $NoQuotes) {
				# Add single quotes for the caller in case they are needed.
				# We use the parser to robustly determine how it will treat
				# the argument.  If we end up with too many tokens, or if
				# the parser found something expandable in the results, we
				# know quotes are needed.
			
				$tokens = $null
				$null = [System.Management.Automation.Language.Parser]::ParseInput("Write-Output $CompletionText", [ref]$tokens, [ref]$null)
				if ($tokens.Length -ne 3 -or ($tokens[1] -is [System.Management.Automation.Language.StringExpandableToken] -and $tokens[1].Kind -eq [System.Management.Automation.Language.TokenKind]::Generic)) {
					$CompletionText = "'$CompletionText'"
				}
			}
			return New-Object System.Management.Automation.CompletionResult($CompletionText, $listItemToUse, $CompletionResultType, $toolTipToUse.Trim())
		}
	}

	function ConvertTo-TeppCompletionEntry {
		[CmdletBinding()]
		param (
			[Parameter(ValueFromPipeline = $true)]
			[AllowNull()]
			$InputObject
		)

		process {
			foreach ($entry in $InputObject) {
				if ($null -eq $entry) { continue }

				$text = $entry -as [string]
				if ($entry.PSObject.Properties.Name -contains 'Text' -and $entry.Text) { $text = $entry.Text -as [string] }
				if ($entry -is [hashtable] -and $entry.Keys -contains 'Text') { $text = $entry['Text'] -as [string] }

				$toolTip = $text
				$listItemText = $text

				if ($entry -is [hashtable]) {
					if ($entry['ToolTip']) { $toolTip = $entry['ToolTip'] -as [string] }
					if ($entry['ListItemText']) { $listItemText = $entry['ListItemText'] -as [string] }
				}
				
				if ($entry.PSObject.Properties.Name -contains 'ToolTip' -and $entry.ToolTip) { $toolTip = $entry.ToolTip -as [string] }
				if ($entry.PSObject.Properties.Name -contains 'ListItemText' -and $entry.ListItemText) { $listItemText = $entry.ListItemText -as [string] }
				[PSCustomObject]@{
					Text         = $text
					ToolTip      = $toolTip
					ListItemText = $listItemText
				}
			}
		}
	}

	$start = Get-Date
	$scriptContainer = [PSFramework.TabExpansion.TabExpansionHost]::Scripts["<name>"]
	if ($scriptContainer.ShouldExecute) {
		$scriptContainer.LastExecution = $start
			
		$innerScript = $scriptContainer.InnerScriptBlock
		[PSFramework.Utility.UtilityHost]::ImportScriptBlock($innerScript)
		$items = @()
		try { $items = & $innerScript | ConvertTo-TeppCompletionEntry }
		catch { $null = $scriptContainer.ErrorRecords.Enqueue($_) }
			
		foreach ($item in ($items | Where-Object Text -Like "$wordToComplete*" | Sort-Object Text)) {
			New-PSFTeppCompletionResult -CompletionText $item.Text -ToolTip $item.ToolTip -ListItemText $item.ListItemText
		}

		$scriptContainer.LastDuration = (Get-Date) - $start
		if ($items) {
			$scriptContainer.LastResult = $items.Text
			$scriptContainer.LastCompletion = $items
		}
	}
	else {
		foreach ($item in ($scriptContainer.LastCompletion | Where-Object Text -Like "$wordToComplete*" | Sort-Object Text)) {
			New-PSFTeppCompletionResult -CompletionText $item.Text -ToolTip $item.ToolTip -ListItemText $item.ListItemText
		}
	}
}