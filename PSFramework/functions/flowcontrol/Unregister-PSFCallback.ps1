function Unregister-PSFCallback
{
<#
	.SYNOPSIS
		Removes a callback from the list of registered callbacks.
	
	.DESCRIPTION
		Removes a callback from the list of registered callbacks.
	
	.PARAMETER Name
		The name of the callback to remove.
		Does NOT support wildcards.
	
	.PARAMETER Callback
		A full callback object to remove.
		Use Get-PSFCallback to get the list of relevant callback objects.
	
	.EXAMPLE
		PS C:\> Unregister-PSFCallback -Name 'MyModule.Configuration'
	
		Unregisters the 'MyModule.Configuration' callback script.
	
	.EXAMPLE
		PS C:\> Get-PSFCallback | Unregister-PSFCallback
	
		Removes all callback scripts applicable to the current runspace.
#>
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Object', Mandatory = $true)]
		[PSFramework.FlowControl.Callback[]]
		$Callback
	)
	
	process
	{
		foreach ($callbackItem in $Callback)
		{
			[PSFramework.FlowControl.CallbackHost]::Remove($callbackItem)
		}
		foreach ($nameString in $Name)
		{
			foreach ($callbackItem in ([PSFramework.FlowControl.CallbackHost]::Get($nameString, $false)))
			{
				if ($callbackItem.Name -ne $nameString) { continue }
				[PSFramework.FlowControl.CallbackHost]::Remove($callbackItem)
			}
		}
	}
}