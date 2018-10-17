function Get-PSFMessageLevelModifier
{
<#
	.SYNOPSIS
		Returns all registered message level modifiers with similar name.
	
	.DESCRIPTION
		Returns all registered message level modifiers with similar name.
	
		Message level modifiers are created using New-PSFMessageLevelModifier and allow dynamically modifying the actual message level written by commands.
	
	.PARAMETER Name
		Default: "*"
		A name filter - only commands that are similar to the filter will be returned.
	
	.EXAMPLE
		PS C:\> Get-PSFMessageLevelModifier
	
		Returns all message level filters
	
	.EXAMPLE
		PS C:\> Get-PSFmessageLevelModifier -Name "mymodule.*"
	
		Returns all message level filters that start with "mymodule."
#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFMessageLevelModifier')]
	Param (
		[string]
		$Name = "*"
	)
	
	([PSFramework.Message.MessageHost]::MessageLevelModifiers.Values) | Where-Object Name -Like $Name
}