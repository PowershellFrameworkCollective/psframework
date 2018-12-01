function Remove-PSFAlias
{
<#
	.SYNOPSIS
		Removes an alias from the global scope.
	
	.DESCRIPTION
		Removes an alias from the global* scope.
		Please note that this always affects the global scope and should not be used lightly.
		This has the potential to break code that does not comply with PowerShell best practices and relies on the use of aliases.
	
		Refuses to delete constant aliases.
		Requires the '-Force' parameter to delete ReadOnly aliases.
	
		*This includes aliases exported by modules.
	
	.PARAMETER Name
		The name of the alias to remove.
	
	.PARAMETER Force
		Enforce removal of aliases. Required to remove ReadOnly aliases (including default aliases such as "select" or "group").
	
	.EXAMPLE
		PS C:\> Remove-PSFAlias -Name 'grep'
	
		Removes the global alias 'grep'
	
	.EXAMPLE
		PS C:\> Remove-PSFAlias -Name 'select' -Force
	
		Removes the default alias 'select'
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
		[string[]]
		$Name,
		
		[switch]
		$Force
	)
	
	process
	{
		foreach ($alias in $Name)
		{
			try { [PSFramework.Utility.UtilityHost]::RemovePowerShellAlias($alias, $Force.ToBool()) }
			catch { Stop-PSFFunction -Message $_ -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ -OverrideExceptionMessage }
		}
	}
}