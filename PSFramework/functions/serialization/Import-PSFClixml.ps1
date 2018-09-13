function Import-PSFClixml
{
<#
	.SYNOPSIS
		Imports objects serialized using Export-Clixml or Export-PSFClixml.
	
	.DESCRIPTION
		Imports objects serialized using Export-Clixml or Export-PSFClixml.
	
		It can handle compressed and non-compressed exports.
	
	.PARAMETER Path
		Path to the files to import.
	
	.PARAMETER Encoding
		Text-based files might be stored with any arbitrary encoding chosen.
		By default, this function assumes UTF8 encoding (the default export encoding for Export-PSFClixml).
	
	.EXAMPLE
		PS C:\> Import-PSFClixml -Path '.\object.xml'
	
		Imports the objects serialized to object.xml in the current folder.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('FullName')]
		[string[]]
		$Path,
		
		[System.Text.Encoding]
		$Encoding = [System.Text.Encoding]::UTF8
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
	}
	process
	{
		try { $resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem }
		catch { Stop-PSFFunction -Message "Failed to resolve path." -ErrorRecord $_ -EnableException $true -Cmdlet $PSCmdlet -Target $Path }
		
		foreach ($pathItem in $resolvedPath)
		{
			if ((Get-Item $pathItem).PSIsContainer)
			{
				Stop-PSFFunction -Message "$pathItem is not a file" -EnableException $true -Target $pathItem
			}
			Write-PSFMessage -Level Verbose -Message "Processing $($pathItem)" -Target $pathItem
			
			[byte[]]$bytes = [System.IO.File]::ReadAllBytes($pathItem)
				
			try { [PSFramework.Serialization.ClixmlSerializer]::FromByteCompressed($bytes) }
			catch
			{
				[string]$string = [System.IO.File]::ReadAllText($pathItem, $Encoding)
				try { [PSFramework.Serialization.ClixmlSerializer]::FromString($string) }
				catch
				{
					try { [PSFramework.Serialization.ClixmlSerializer]::FromStringCompressed($string) }
					catch
					{
						try { [PSFramework.Serialization.ClixmlSerializer]::FromByte($bytes) }
						catch
						{
							Stop-PSFFunction -Message "Failed to convert input object" -EnableException $true -Target $pathItem -Cmdlet $PSCmdlet
						}
					}
				}
				
			}
		}
	}
}