function ConvertFrom-PSFClixml
{
<#
	.SYNOPSIS
		Converts data that was serialized from an object back into that object.
	
	.DESCRIPTION
		Converts data that was serialized from an object back into that object.
	
		Use Import-PSFclixml to restore objects serialized and written to file.
		This command is designed for converting serialized data in memory, for example to expand objects returned by a network api.
	
	.PARAMETER InputObject
		The serialized data to restore to objects.
	
	.EXAMPLE
		PS C:\> $data | ConvertFrom-PSFClixml
	
		Converts the data stored in $data back into objects
#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		$InputObject
	)
	
	begin
	{
		$byteList = New-Object System.Collections.ArrayList
		
		function Convert-Item
		{
			[CmdletBinding()]
			param (
				$Data
			)
			
			if ($Data -is [System.String])
			{
				try { [PSFramework.Serialization.ClixmlSerializer]::FromStringCompressed($Data) }
				catch { [PSFramework.Serialization.ClixmlSerializer]::FromString($Data) }
			}
			else
			{
				try { [PSFramework.Serialization.ClixmlSerializer]::FromByteCompressed($Data) }
				catch { [PSFramework.Serialization.ClixmlSerializer]::FromByte($Data) }
			}
		}
	}
	process
	{
		if ($InputObject -is [string]) { Convert-Item -Data $InputObject }
		elseif ($InputObject -is [System.Byte[]]) { Convert-Item -Data $InputObject }
		elseif ($InputObject -is [System.Byte]) { $null = $byteList.Add($InputObject) }
		else { Stop-PSFFunction -String 'ConvertFrom-PSFClixml.BadInput' -EnableException $true }
	}
	end
	{
		if ($byteList.Count -gt 0)
		{
			Convert-Item -Data ([System.Byte[]]$byteList.ToArray())
		}
	}
}