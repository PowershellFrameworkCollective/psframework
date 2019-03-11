function ConvertTo-PSFHashtable
{
<#
	.SYNOPSIS
		Converts an object into a hashtable.
	
	.DESCRIPTION
		Converts an object into a hashtable.
		Can exclude individual properties from being included.
	
	.PARAMETER Exclude
		The propertynames to exclude.
		Must be full property-names, no wildcard/regex matching.
	
	.PARAMETER Include
		The propertynames to include.
		Must be full property-names, no wildcard/regex matching.
	
	.PARAMETER IncludeEmpty
		By default, only properties on the input object are included.
		In order to force all properties defiend in -Include to be included, specify this switch.
		Keys added through this have an empty ($null) value.
	
	.PARAMETER InputObject
		The object(s) to convert
	
	.EXAMPLE
		PS C:\> Get-ChildItem | ConvertTo-PSFHashtable
		
		Scans all items in the current path and converts those objects into hashtables.
#>
	[OutputType([System.Collections.Hashtable])]
	[CmdletBinding()]
	Param (
		[string[]]
		$Exclude,
		
		[string[]]
		$Include,
		
		[switch]
		$IncludeEmpty,
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)
	
	process
	{
		foreach ($item in $InputObject)
		{
			if ($null -eq $item) { continue }
			if ($item -is [System.Collections.Hashtable])
			{
				$hashTable = $item.Clone()
				foreach ($name in $Exclude) { $hashTable.Remove($name) }
				if ($Include)
				{
					foreach ($key in ([object[]]$hashTable.Keys))
					{
						if ($key -notin $Include) { $hashTable.Remove($key) }
					}
					if (-not $IncludeEmpty) { continue }
					foreach ($key in $Include)
					{
						if ($hashTable.Keys -notcontains $key) { $hashTable[$key] = $null }
					}
				}
				$hashTable
			}
			elseif ($item -is [System.Collections.IDictionary])
			{
				$hashTable = @{ }
				foreach ($name in $item.Keys)
				{
					if ($name -in $Exclude) { continue }
					if ($Include -and ($name -notin $Include)) { continue }
					$hashTable[$name] = $item[$name]
				}
				if ($Include -and $IncludeEmpty)
				{
					foreach ($key in $Include)
					{
						if ($hashTable.Keys -notcontains $key) { $hashTable[$key] = $null }
					}
				}
				$hashTable
			}
			else
			{
				$hashTable = @{ }
				foreach ($property in $item.PSObject.Properties)
				{
					if ($property.Name -in $Exclude) { continue }
					if ($Include -and ($property.Name -notin $Include)) { continue }
					
					$hashTable[$property.Name] = $property.Value
				}
				if ($Include -and $IncludeEmpty)
				{
					foreach ($key in $Include)
					{
						if ($hashTable.Keys -notcontains $key) { $hashTable[$key] = $null }
					}
				}
				$hashTable
			}
		}
	}
}