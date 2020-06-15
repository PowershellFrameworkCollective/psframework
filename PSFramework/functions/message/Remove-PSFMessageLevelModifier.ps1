function Remove-PSFMessageLevelModifier
{
	<#
		.SYNOPSIS
			Removes a message level modifier.
		
		.DESCRIPTION
			Removes a message level modifier.
	
			Message Level Modifiers can be created by using New-PSFMessageLevelModifier.
			They are used to emphasize or deemphasize messages, in order to help with debugging.
		
		.PARAMETER Name
			Name of the message level modifier to remove.
		
		.PARAMETER Modifier
			The actual modifier to remove, as returned by Get-PSFMessageLevelModifier.
		
		.PARAMETER EnableException
			This parameters disables user-friendly warnings and enables the throwing of exceptions.
			This is less user friendly, but allows catching exceptions in calling scripts.
		
		.EXAMPLE
			PS C:\> Get-PSFMessageLevelModifier | Remove-PSFMessageLevelModifier
	
			Removes all message level modifiers, restoring everything to their default levels.
	
		.EXAMPLE
			PS C:\> Remove-PSFMessageLevelModifier -Name "mymodule.foo"
	
			Removes the message level modifier named "mymodule.foo"
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Remove-PSFMessageLevelModifier')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Message.MessageLevelModifier[]]
		$Modifier,
		
		[switch]
		$EnableException
	)
	
	process
	{
		foreach ($item in $Name)
		{
			if ($item -eq "PSFramework.Message.MessageLevelModifier") { continue }
			
			if ([PSFramework.Message.MessageHost]::MessageLevelModifiers.ContainsKey($item))
			{
				$dummy = $null
				$null = [PSFramework.Message.MessageHost]::MessageLevelModifiers.TryRemove($item, [ref] $dummy)
			}
			else
			{
				Stop-PSFFunction -Message "No message level modifier of name $item found!" -EnableException $EnableException -Category InvalidArgument -Tag 'fail','input','level','message' -Continue
			}
		}
		foreach ($item in $Modifier)
		{
			if ([PSFramework.Message.MessageHost]::MessageLevelModifiers.ContainsKey($item.Name))
			{
				$dummy = $null
				$null = [PSFramework.Message.MessageHost]::MessageLevelModifiers.TryRemove($item.Name, [ref]$dummy)
			}
			else
			{
				Stop-PSFFunction -Message "No message level modifier of name $($item.Name) found!" -EnableException $EnableException -Category InvalidArgument -Tag 'fail', 'input', 'level', 'message' -Continue
			}
		}
	}
}