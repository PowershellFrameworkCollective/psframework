function Get-PSFUserChoice
{
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
	
	.PARAMETER Caption
		The title of the question, so the user knows what it is all about.
	
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
		[string[]]
		$Options,
		
		[string]
		$Caption,
		
		[string]
		$Message,
		
		[int]
		$DefaultChoice = 0
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
		$choices = @()
		foreach ($option in $Options)
		{
			if ($option -match "&") { $choices += New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList $option, $option }
			else { $choices += New-Object System.Management.Automation.Host.ChoiceDescription -ArgumentList "&$($option.Trim())", $option }
		}
	}
	process
	{
		$Host.UI.PromptForChoice($Caption, $Message, $choices, $DefaultChoice)
	}
}