function Export-PSFPowerShellDataFile {
	<#
	.SYNOPSIS
		Exports data into psd1 config files.
	
	.DESCRIPTION
		Exports data into psd1 config files.

		Use Register-PSFPsd1Converter to extend/customize how this conversion happens.
	
	.PARAMETER Path
		The path where to write to.
		The parent folder must exist.
		May provide multiple paths.
	
	.PARAMETER Depth
		How many levels deep do you want to process sub-properties?
		Defaults to 2

	.PARAMETER Encoding
		The encoding to write the text file in.
		Defaults to: UTF8 (with BOM).
	
	.PARAMETER EnableVerbose
		Enables deep verbosity when processing objects.
		By default, individual conversion steps are not tracked for performance reasons.
		Enable this for extensive amounts of debug messages.
	
	.PARAMETER Configuration
		Additional configuration settings to provide for the conversion.
		Custom converters may use these as implemented in their custom conversion.
	
	.PARAMETER InputObject
		The object(s) to convert and write to file.
	
	.EXAMPLE
		PS C:\> Get-ChildItem | Export-PSFPowerShellDataFile -Path .\files.psd1

		Takes all files and folders and converts the data into psd1-style data structures, then write that to "files.psd1" in the current path..
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSFNewFile]
		$Path,

		[int]
		$Depth = 2,

		[PSFArgumentCompleter('PSFramework-Encoding')]
		[PSFEncoding]
		$Encoding = 'UTF8',

		[switch]
		$EnableVerbose,

		[Hashtable]
		$Configuration = @{},

		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[AllowNull()]
		$InputObject
	)
	begin {
		$converter = [PSFramework.Data.Psd1Converter]::new()
		$converter.Depth = $Depth
		$converter.EnableVerbose = $EnableVerbose
		$converter.Config = $Configuration
		$converter.Cmdlet = $PSCmdlet

		$writer = { Set-PSFFileContent -Path $filePath -Encoding $Encoding }.GetSteppablePipeline()
		$writer.Begin($true)
	}
	process {
		$writer.Process($converter.Convert($InputObject))
	}
	end {
		$writer.End()
	}
}