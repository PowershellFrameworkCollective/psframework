function Get-PSFUserChoice {
    <#
	.SYNOPSIS
		Prompts the user to choose between a set of options.
	
	.DESCRIPTION
		Prompts the user to choose between a set of options.
		Returns the index of the choice picked as a number.
	
	.PARAMETER Options
		The options the user may pick from.
		The user selects a choice by specifying the letter associated with a choice.
		The letter assigned to a choice is picked from the character after the first '&' in any specified string.
		If there is no '&', the system will automatically pick the first letter as choice letter:
		"This &is an example" will have the character "i" bound for the choice.
		"This is &an example" will have the character "a" bound for the choice.
		"This is an example" will have the character "T" bound for the choice.
	
		This parameter takes both strings and hashtables (in any combination).
		A hashtable is expected to have two properties, 'Label' and 'Help'.
		Label is the text shown in the initial prompt, help what the user sees when requesting help.
	
	.PARAMETER Caption
		The title of the question, so the user knows what it is all about.

    .PARAMETER Vertical
        Displays the options vertically, one per line, rather than the default side-by-side display.
        Each option will be numbered.
        Option numbering starts at 1, return will always be one lower than the selected number.
	
	.PARAMETER Message
		A message to offer to the user. Be more specific about the implications of this choice.
	
	.PARAMETER DefaultChoice
		The index of the choice made by default.
		By default, the first option is selected as default choice.
	
	.EXAMPLE
		PS C:\> Get-PSFUserChoice -Options "1) Create a new user", "2) Disable a user", "3) Unlock an account", "4) Get a cup of coffee", "5) Exit" -Caption "User administration menu" -Message "What operation do you want to perform?"
	
		Prompts the user for what operation to perform from the set of options provided
#>
    [OutputType([System.Int32])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]
        $Options,
		
        [string]
        $Caption,

        [switch]
        $Vertical,
		
        [string]
        $Message,
		
        [int]
        $DefaultChoice = 0
    )
	
    begin {
        #region Vertical Options Display
        if ($Vertical) {
            $optionStrings = foreach ($option in $Options) {
                if ($option -is [hashtable]) { $option.Keys }
                else { $option }
            }
            $count = 1
            $messageStrings = foreach ($optionString in $OptionStrings) {
                "$count $optionString"
                $count++
            }
            $count--
            $Message = ((@($Message) + @($messageStrings)) -join "`n").Trim()
            $choices = 1..$count | ForEach-Object { "&$_" }
        }
        #endregion Vertical Options Display

        #region Default Options Display
        else {
            $choices = @()
            foreach ($option in $Options) {
                if ($option -is [hashtable]) {
                    $label = $option.Keys -match '^l' | Select-Object -First 1
                    [string]$labelValue = $option[$label]
                    $help = $option.Keys -match '^h' | Select-Object -First 1
                    [string]$helpValue = $option[$help]
				
                }
                else {
                    $labelValue = "$option"
                    $helpValue = "$option"
                }
                if ($labelValue -match "&") { $choices += New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList $labelValue, $helpValue }
                else { $choices += New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList "&$($labelValue.Trim())", $helpValue }
            }
        }
        #endregion Default Options Display
    }
    process {
        # Will error on one option so we just return the value 0 (which is the result of the only option the user would have)
        # This is for cases where the developer dynamically assembles options so that they don't need to ensure a minimum of two options.
        if ($Options.Count -eq 1) { return 0 }
		
        $Host.UI.PromptForChoice($Caption, $Message, $choices, $DefaultChoice)
    }
}