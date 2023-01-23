function ConvertTo-PSFClixml
{
<#
	.SYNOPSIS
		Converts an input object into a serialized string or byte array.
	
	.DESCRIPTION
		Converts an input object into a serialized string or byte array.
		Works analogous to Export-PSFClixml, only it does not require being written to file.
	
	.PARAMETER Depth
		Specifies how many levels of contained objects are included in the XML representation. The default value is 2.
	
	.PARAMETER InputObject
		The object(s) to serialize.
	
	.PARAMETER Style
		Whether to export as byte (better compression) or as string (often easier to transmit using other utilities/apis).
	
	.PARAMETER NoCompression
		By default, exported data is compressed, saving a lot of storage at the cost of some CPU cycles.
		This switch disables this compression, making string-style exports compatible with Import-Clixml.
	
	.EXAMPLE
		PS C:\> Get-ChildItem | ConvertTo-PSFClixml
	
		Scans all items in the current folder and then converts that into a compressed clixml string.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	param (
		[int]
		$Depth,
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[PSFramework.Serialization.ClixmlDataStyle]
		$Style = 'String',
		
		[switch]
		$NoCompression
	)
	
	begin
	{
		$data = [System.Collections.ArrayList]@()
	}
	process
	{
		$null = $data.Add($InputObject)
	}
	end
	{
		try
		{
			if ($Style -like 'Byte')
			{
				if ($NoCompression)
				{
					if ($Depth) { [PSFramework.Serialization.ClixmlSerializer]::ToByte($data.ToArray(), $Depth) }
					else { [PSFramework.Serialization.ClixmlSerializer]::ToByte($data.ToArray()) }
				}
				else
				{
					if ($Depth) { [PSFramework.Serialization.ClixmlSerializer]::ToByteCompressed($data.ToArray(), $Depth) }
					else { [PSFramework.Serialization.ClixmlSerializer]::ToByteCompressed($data.ToArray()) }
				}
			}
			else
			{
				if ($NoCompression)
				{
					if ($Depth) { [PSFramework.Serialization.ClixmlSerializer]::ToString($data.ToArray(), $Depth) }
					else { [PSFramework.Serialization.ClixmlSerializer]::ToString($data.ToArray()) }
				}
				else
				{
					if ($Depth) { [PSFramework.Serialization.ClixmlSerializer]::ToStringCompressed($data.ToArray(), $Depth) }
					else { [PSFramework.Serialization.ClixmlSerializer]::ToStringCompressed($data.ToArray()) }
				}
			}
		}
		catch
		{
			Stop-PSFFunction -String 'ConvertTo-PSFClixml.Conversion.Error' -ErrorRecord $_ -EnableException $true -Target $resolvedPath -Cmdlet $PSCmdlet
		}
	}
}