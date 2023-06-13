function Unregister-PSFMessageColorTransform {
	<#
	.SYNOPSIS
		Removes a previously registered message color rule.
	
	.DESCRIPTION
		Removes a previously registered message color rule.
	
	.PARAMETER Name
		Name of the rule to remove.
	
	.EXAMPLE
		PS C:\> Get-PSFMessageColorTransform | Unregister-PSFMessageColorTransform
		
		Clears all message color rules..
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	process {
		foreach ($conditionName in $Name) {
			$null = [PSFramework.Message.MessageHost]::ColorTransforms.TryRemove($conditionName, [ref]$null)
		}
	}
}