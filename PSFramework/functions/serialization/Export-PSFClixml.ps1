function Export-PSFClixml
{
<#
	.SYNOPSIS
		Writes objects to the filesystem.
	
	.DESCRIPTION
		Writes objects to the filesystem.
		In opposite to the default Export-Clixml cmdlet, this function offers data compression as the default option.
		
		Exporting to regular clixml is still supported though.
	
	.PARAMETER Path
		The path to write to.
	
	.PARAMETER Depth
		Specifies how many levels of contained objects are included in the XML representation. The default value is 2.
	
	.PARAMETER InputObject
		The object(s) to serialize.
	
	.PARAMETER Style
		Whether to export as byte (better compression) or as string (often easier to transmit using other utilities/apis).
	
	.PARAMETER NoCompression
		By default, exported data is compressed, saving a lot of storage at the cost of some CPU cycles.
		This switch disables this compression, making string-style exports compatible with Import-Clixml.
	
	.PARAMETER PassThru
		Passes all objects along the pipeline.
		By default, Export-PSFClixml does not produce output.
	
	.PARAMETER Encoding
		The encoding to use when using string-style export.
		By default, it exports as UTF8 encoding.
	
	.EXAMPLE
		PS C:\> Get-ChildItem | Export-PSFClixml -Path 'C:\temp\data.byte'
		
		Exports a list of all items in the current path as compressed binary file to C:\temp\data.byte
	
	.EXAMPLE
		PS C:\> Get-ChildItem | Export-PSFClixml -Path C:\temp\data.xml -Style 'String' -NoCompression
		
		Exports a list of all items in the current path as a default clixml readable by Import-Clixml
#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Export-PSFClixml')]
	param (
		[PsfValidateScript('PSFramework.Validate.FSPath.FileOrParent', ErrorString = 'PSFramework.Validate.FSPath.FileOrParent')]
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Path,
		
		[int]
		$Depth,
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[PSFramework.Serialization.ClixmlDataStyle]
		$Style = 'Byte',
		
		[switch]
		$NoCompression,
		
		[switch]
		$PassThru,
		
		[PSFEncoding]
		$Encoding = (Get-PSFConfigValue -FullName 'PSFramework.Text.Encoding.DefaultWrite')
	)
	
	begin
	{
		try { $resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem -SingleItem -NewChild }
		catch { Stop-PSFFunction -String 'Validate.FSPath.FileOrParent' -StringValues $Path -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ }
		[System.Collections.ArrayList]$data = @()
	}
	process
	{
		$null = $data.Add($InputObject)
		if ($PassThru) { $InputObject }
	}
	end
	{
		try
		{
			Write-PSFMessage -Level Verbose -String 'Export-PSFClixml.Exporting' -StringValues $resolvedPath
			if ($Style -like 'Byte')
			{
				if ($NoCompression)
				{
					if ($Depth) { [System.IO.File]::WriteAllBytes($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToByte($data.ToArray(), $Depth))) }
					else { [System.IO.File]::WriteAllBytes($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToByte($data.ToArray()))) }
				}
				else
				{
					if ($Depth) { [System.IO.File]::WriteAllBytes($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToByteCompressed($data.ToArray(), $Depth))) }
					else { [System.IO.File]::WriteAllBytes($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToByteCompressed($data.ToArray()))) }
				}
			}
			else
			{
				if ($NoCompression)
				{
					if ($Depth) { [System.IO.File]::WriteAllText($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToString($data.ToArray(), $Depth)), $Encoding) }
					else { [System.IO.File]::WriteAllText($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToString($data.ToArray())), $Encoding) }
				}
				else
				{
					if ($Depth) { [System.IO.File]::WriteAllText($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToStringCompressed($data.ToArray(), $Depth)), $Encoding) }
					else { [System.IO.File]::WriteAllText($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToStringCompressed($data.ToArray())), $Encoding) }
				}
			}
		}
		catch
		{
			Stop-PSFFunction -String 'Export-PSFClixml.Exporting.Failed' -ErrorRecord $_ -EnableException $true -Target $resolvedPath -Cmdlet $PSCmdlet
		}
	}
}