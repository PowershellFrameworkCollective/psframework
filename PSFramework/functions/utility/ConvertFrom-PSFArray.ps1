function ConvertFrom-PSFArray
{
<#
	.SYNOPSIS
		Flattens properties that have array values.
	
	.DESCRIPTION
		Flattens properties that have array values.
		With this you can prepare objects for export to systems that cannot handle collection in propertyvalues.
		This flattening happens using a string join operation, so the output on modified properties is guaranteed to be a string.
	
	.PARAMETER JoinBy
		The string sequence to join values by.
		Defaults to ", "
	
	.PARAMETER PropertyName
		The properties to affect.
		Interprets wildcards, defaults to '*'.
	
	.PARAMETER InputObject
		The objects the properties of which to flatten.
	
	.EXAMPLE
		PS C:\> Get-Something | ConvertFrom-PSFArray | Export-Csv -Path .\output.csv
	
		Processes the output of Get-Something in order to produce a flat table to export data to csv without trimming collections.
#>
	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[string]
		$JoinBy = ', ',
		
		[Parameter(Position = 1)]
		[string[]]
		$PropertyName = '*',
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)
	
	process
	{
		$props = [ordered]@{ }
		foreach ($property in $InputObject.PSObject.Properties)
		{
			#region Skip non-collection properties
			if ($property.Value -isnot [System.Collections.ICollection])
			{
				$props[$property.Name] = $property.Value
				continue
			}
			#endregion Skip non-collection properties
			
			#region Handle whether the property should be processed at all
			$found = $false
			foreach ($name in $PropertyName)
			{
				if ($property.Name -like $name)
				{
					$found = $true
					break
				}
			}
			if (-not $found)
			{
				$props[$property.Name] = $property.Value
				continue
			}
			#endregion Handle whether the property should be processed at all
			
			$props[$property.Name] = $property.Value -join $JoinBy
		}
		[PSCustomObject]$props
	}
}