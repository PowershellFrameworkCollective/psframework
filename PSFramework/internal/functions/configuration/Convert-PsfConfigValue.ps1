function Convert-PsfConfigValue
{
<#
	.SYNOPSIS
		Converts a persisted configuration's value back to its data type.
	
	.DESCRIPTION
		Converts a persisted configuration's value back to its data type.
		Can be used for either registry-based or json-file-based items.
	
	.PARAMETER Value
		The full value item to decode (must include the original type identifier).
		Example:
		  "bool:true"
	
	.EXAMPLE
		PS C:\> Convert-PsfConfigValue -Value "bool:true"
	
		Will return a boolean $true
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	Param (
		[string]
		$Value
	)
	
	process
	{
		$index = $Value.IndexOf(":")
		if ($index -lt 1) { throw "No type identifier found!" }
		$type = $Value.Substring(0, $index)
		$content = $Value.Substring($index + 1)
		
		switch ($type)
		{
			"bool"
			{
				if ($content -eq "true") { return $true }
				if ($content -eq "1") { return $true }
				if ($content -eq "false") { return $false }
				if ($content -eq "0") { return $false }
				throw "Failed to interpret as bool: $content"
			}
			"int" { return ([int]$content) }
			"double" { return [double]$content }
			"long" { return [long]$content }
			"string" { return $content }
			"timespan" { return (New-Object System.TimeSpan($content)) }
			"datetime" { return (New-Object System.DateTime($content)) }
			"consolecolor" { return ([System.ConsoleColor]$content) }
			"array"
			{
				if ($content -eq "") { return, @() }
				$tempArray = foreach ($item in ($content -split "þþþ"))
				{
					Convert-PsfConfigValue -Value $item
				}
				return, $tempArray
			}
			
			default { throw "Unknown type identifier" }
		}
	}
}