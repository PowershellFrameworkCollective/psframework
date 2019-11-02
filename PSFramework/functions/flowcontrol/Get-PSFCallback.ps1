function Get-PSFCallback
{
<#
	.SYNOPSIS
		Returns a list of callback scripts.
	
	.DESCRIPTION
		Returns a list of callback scripts.
		Use Register-PSFCallback to register new callback scripts.
		Use Unregister-PSFCallback to remove callback scripts.
		Use Invoke-PSFCallback within a function of your module to execute all registered callback scripts that apply.
	
	.PARAMETER Name
		The name to filter by.
	
	.PARAMETER All
		Return all callback scripts, even those specific to other runspaces.
	
	.EXAMPLE
		PS C:\> Get-PSFCallback
	
		Returns all callback scripts relevant to the current runspace.
	
	.EXAMPLE
		PS C:\> Get-PSFCallback -All
	
		Returns all callback scripts in the entire process.
	
	.EXAMPLE
		PS C:\> Get-PSFCallback -Name MyModule.Configuration
	
		Returns the callback script named 'MyModule.Configuration'
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[OutputType([PSFramework.FlowControl.Callback])]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name = '*',
		
		[switch]
		$All
	)
	
	process
	{
		foreach ($nameString in $Name)
		{
			[PSFramework.FlowControl.CallbackHost]::Get($nameString, $All.ToBool())
		}
	}
}