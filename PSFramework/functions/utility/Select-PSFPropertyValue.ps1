function Select-PSFPropertyValue
{
<#
	.SYNOPSIS
		Expand specific property values based on selection logic.
	
	.DESCRIPTION
		This command allows picking a set of properties and then returning ...
		- All their values
		- The value that meets specific rules
		- A composite value
	
	.PARAMETER Property
		The properties to work with, in the order they should be considered.
	
	.PARAMETER Fallback
		Whether to fall back on other properties if the first one doesn't contain values.
		This picks the value of the first property that actually has a value.
	
	.PARAMETER Select
		Select either the largest or lowest propertyvalue in the Propertynames specified.
	
	.PARAMETER JoinBy
		Joins the selected properties by the string specified.
	
	.PARAMETER FormatWith
		Formats the selected properties into the specified format string.
	
	.PARAMETER InputObject
		The object(s) whose properties to inspect.
	
	.EXAMPLE
		PS C:\> Get-ADComputer -Filter * | Select-PSFPropertyValue -Property 'DNSHostName', 'Name' -Fallback
		
		For each computer in the domain, it will pick the DNSHostName if available, otherwise the Name.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string[]]
		$Property,
		
		[Parameter(ParameterSetName = 'Fallback')]
		[switch]
		$Fallback,
		
		[Parameter(ParameterSetName = 'Select')]
		[ValidateSet('Lowest', 'Largest')]
		[string]
		$Select,
		
		[Parameter(ParameterSetName = 'Join')]
		[string]
		$JoinBy,
		
		[Parameter(ParameterSetName = 'Format')]
		[string]
		$FormatWith,
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)
	
	process
	{
		foreach ($object in $InputObject)
		{
			switch ($PSCmdlet.ParameterSetName)
			{
				'Default'
				{
					foreach ($prop in $Property)
					{
						$object.$Prop
					}
				}
				'Fallback'
				{
					foreach ($prop in $Property)
					{
						if ($null -ne ($object.$Prop | Remove-PSFNull -Enumerate))
						{
							$object.$prop
							break
						}
					}
				}
				'Select'
				{
					$values = @()
					foreach ($prop in $Property)
					{
						$values += $object.$Prop
					}
					if ($Select -eq 'Largest') { $values | Sort-Object -Descending | Select-Object -First 1 }
					else { $values | Sort-Object | Select-Object -First 1 }
					
				}
				'Join'
				{
					$values = @()
					foreach ($prop in $Property)
					{
						$values += $object.$Prop
					}
					$values -join $JoinBy
				}
				'Format'
				{
					$values = @()
					foreach ($prop in $Property)
					{
						$values += $object.$Prop
					}
					$FormatWith -f $values
				}
			}
		}
	}
}