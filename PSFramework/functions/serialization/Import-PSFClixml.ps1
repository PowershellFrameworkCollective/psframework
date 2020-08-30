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
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Import-PSFClixml')]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('FullName')]
		[string[]]
		$Path,
		
		[PSFEncoding]
		$Encoding = (Get-PSFConfigValue -FullName 'psframework.text.encoding.defaultread' -Fallback 'utf-8')
	)
	
	process
	{
		try { $resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem }
		catch { Stop-PSFFunction -String 'Import-PSFClixml.Path.Resolution' -StringValues $Path -ErrorRecord $_ -EnableException $true -Cmdlet $PSCmdlet -Target $Path }
		
		foreach ($pathItem in $resolvedPath)
		{
			if ((Get-Item $pathItem).PSIsContainer)
			{
				Stop-PSFFunction -String 'Import-PSFClixml.Path.NotFile' -StringValues $pathItem -EnableException $true -Target $pathItem
			}
			Write-PSFMessage -Level Verbose -String 'Import-PSFClixml.Processing' -StringValues $pathItem -Target $pathItem
			
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
							Stop-PSFFunction -String 'Import-PSFClixml.Conversion.Failed' -EnableException $true -Target $pathItem -Cmdlet $PSCmdlet
						}
					}
				}
				
			}
		}
	}
}