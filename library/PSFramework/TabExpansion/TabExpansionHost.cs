using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Language;
using PSFramework.Parameter;

namespace PSFramework.TabExpansion
{
    /// <summary>
    /// Class that handles the static fields supporting the ÜSFramework TabExpansion implementation
    /// </summary>
    public static class TabExpansionHost
    {
        #region State information
        /// <summary>
        /// Field containing the scripts that were registered.
        /// </summary>
        public static ConcurrentDictionary<string, ScriptContainer> Scripts = new ConcurrentDictionary<string, ScriptContainer>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The cache used by scripts utilizing TabExpansionPlusPlus for PSFramework
        /// </summary>
        public static Hashtable Cache
        {
            get
            {
                lock(_CacheLock)
                    return _Cache;
            }
            set
            {
                lock(_CacheLock)
                    _Cache = value;
            }
        }
        private static Hashtable _Cache = new Hashtable(StringComparer.InvariantCultureIgnoreCase);
        private static readonly object _CacheLock = new object();
        #endregion State information

        #region Public logic access
        /// <summary>
        /// Registers a new completion scriptblock
        /// </summary>
        /// <param name="Name">The name of the completion scriptblock</param>
        /// <param name="ScriptBlock">The scriptblock that will provide completion data</param>
        /// <param name="Mode">What completion mode to use</param>
        /// <param name="CacheDuration">How long the gathered pieces of data remain valid.</param>
        /// <param name="Global">Whether to globalize scriptblocks prior to invocation.</param>
        public static void RegisterCompletion(string Name, ScriptBlock ScriptBlock, TeppScriptMode Mode, TimeSpanParameter CacheDuration, bool Global)
        {
            ScriptContainer script = new ScriptContainer();
            script.Name = Name;
            script.LastDuration = new TimeSpan(-1);
            script.LastResultsValidity = CacheDuration;
            script.Global = Global;

            TeppScriptMode effectiveMode = Mode;
            if (effectiveMode == TeppScriptMode.Auto)
            {
                effectiveMode = TeppScriptMode.Full;
                if (((ScriptBlock.Ast as ScriptBlockAst) != null) && ((ScriptBlockAst)ScriptBlock.Ast).ParamBlock == null)
                    effectiveMode = TeppScriptMode.Simple;
            }

            if (effectiveMode == TeppScriptMode.Full)
                script.ScriptBlock = ScriptBlock;
            else
            {
                script.ScriptBlock = ScriptBlock.Create(_SimpleCompletionScript.Replace("<name>", Name));
                script.InnerScriptBlock = ScriptBlock;
            }
            Scripts[Name] = script;
        }

        /// <summary>
        /// Registers a new completion scriptblock
        /// </summary>
        /// <param name="Name">The name of the completion scriptblock</param>
        /// <param name="ScriptBlock">The scriptblock that will provide completion data</param>
        /// <param name="Mode">What completion mode to use</param>
        /// <param name="CacheDuration">How long the gathered pieces of data remain valid.</param>
        /// <param name="Global">Whether to globalize scriptblocks prior to invocation.</param>
        /// <param name="PassThru">Parameter is ignored. Needed to have a second signature that returns the script container.</param>
        public static ScriptContainer RegisterCompletion(string Name, ScriptBlock ScriptBlock, TeppScriptMode Mode, TimeSpanParameter CacheDuration, bool Global, bool PassThru)
        {
            RegisterCompletion(Name, ScriptBlock, Mode, CacheDuration, Global);
            return Scripts[Name];
        }

        private static string _SimpleCompletionScript = @"
param (
	$commandName,
		
	$parameterName,
		
	$wordToComplete,
		
	$commandAst,
		
	$fakeBoundParameter
)

function New-PSFTeppCompletionResult
{
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
	
	process
	{
		$toolTipToUse = if ($ToolTip -eq '') { $CompletionText }
		else { $ToolTip }
		$listItemToUse = if ($ListItemText -eq '') { $CompletionText }
		else { $ListItemText }
		
		# If the caller explicitly requests that quotes
		# not be included, via the -NoQuotes parameter,
		# then skip adding quotes.
		
		if ($CompletionResultType -eq [System.Management.Automation.CompletionResultType]::ParameterValue -and -not $NoQuotes)
		{
			# Add single quotes for the caller in case they are needed.
			# We use the parser to robustly determine how it will treat
			# the argument.  If we end up with too many tokens, or if
			# the parser found something expandable in the results, we
			# know quotes are needed.
			
			$tokens = $null
			$null = [System.Management.Automation.Language.Parser]::ParseInput(""echo $CompletionText"", [ref]$tokens, [ref]$null)
			if ($tokens.Length -ne 3 -or($tokens[1] -is [System.Management.Automation.Language.StringExpandableToken] -and $tokens[1].Kind -eq [System.Management.Automation.Language.TokenKind]::Generic))
			{
				$CompletionText = ""'$CompletionText'""
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

			if ($entry.Text -and $entry.ToolTip) {
				if ($entry -is [hashtable]) { [PSCustomObject]$entry }
				else { $entry }
				continue
			}

			[PSCustomObject]@{
				Text = $entry -as [string]
				ToolTip = $entry -as [string]
			}
		}
	}
}

$start = Get-Date
$scriptContainer = [PSFramework.TabExpansion.TabExpansionHost]::Scripts[""<name>""]
if ($scriptContainer.ShouldExecute)
{
	$scriptContainer.LastExecution = $start
			
	$innerScript = $scriptContainer.InnerScriptBlock
    [PSFramework.Utility.UtilityHost]::ImportScriptBlock($innerScript)
	# Use Write-Output to enumerate arrays properly, avoids trouble with persisting cached results
	try { $items = $innerScript.Invoke() | ConvertTo-TeppCompletionEntry }
	catch { $null = $scriptContainer.ErrorRecords.Enqueue($_) }
			
	foreach ($item in ($items | Where-Object Text -like ""$wordToComplete*"" | Sort-Object Text))
	{
		New-PSFTeppCompletionResult -CompletionText $item.Text -ToolTip $item.ToolTip
	}

	$scriptContainer.LastDuration = (Get-Date) - $start
	if ($items) {
		$scriptContainer.LastResult = $items.Text
		$scriptContainer.LastCompletion = $items
	}
}
else
{
	foreach ($item in ($scriptContainer.LastCompletion | Where-Object Text -like ""$wordToComplete*"" | Sort-Object Text))
	{
		New-PSFTeppCompletionResult -CompletionText $item.Text -ToolTip $item.ToolTip
	}
}
";
        #endregion Public logic access

        #region Resources for individual tab completions
        /// <summary>
        /// Dictionary containing a list of hashtables to explicitly add properties when completing for specific output types.
        /// Entries must have three properties:
        /// - Name (Name of Property)
        /// - Type (Type, not Typename, of the property. May be empty)
        /// - TypeKnown (Boolean, whether the type is known)
        /// Used by the Tab Completion: PSFramework-Input-ObjectProperty
        /// </summary>
        public static ConcurrentDictionary<string, object[]> InputCompletionTypeData = new ConcurrentDictionary<string, object[]>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Dictionary containing a list of hashtables to explicitly add properties when completing for specific commands
        /// Entries must have three properties:
        /// - Name (Name of Property)
        /// - Type (Type, not Typename, of the property. May be empty)
        /// - TypeKnown (Boolean, whether the type is known)
        /// Used by the Tab Completion: PSFramework-Input-ObjectProperty
        /// </summary>
        public static ConcurrentDictionary<string, object[]> InputCompletionCommandData = new ConcurrentDictionary<string, object[]>(StringComparer.InvariantCultureIgnoreCase);
        #endregion Resources for individual tab completions
    }
}
