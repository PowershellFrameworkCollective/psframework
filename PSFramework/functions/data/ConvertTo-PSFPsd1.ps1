function ConvertTo-PSFPsd1 {
	<#
	.SYNOPSIS
		Converts objects into PSD1 configuration text.
		
	.DESCRIPTION
		Converts objects into PSD1 configuration text.

		Use Register-PSFPsd1Converter to extend/customize how this conversion happens.
	
	.PARAMETER Depth
		How many levels deep do you want to process sub-properties?
		Defaults to 2
	
	.PARAMETER EnableVerbose
		Enables deep verbosity when processing objects.
		By default, individual conversion steps are not tracked for performance reasons.
		Enable this for extensive amounts of debug messages.
	
	.PARAMETER Configuration
		Additional configuration settings to provide for the conversion.
		Custom converters may use these as implemented in their custom conversion.
	
	.PARAMETER InputObject
		The object(s) to convert.
	
	.EXAMPLE
		PS C:\> Get-ChildItem | ConvertTo-PSFPsd1

		Takes all files and folders and converts the data into psd1-style data structures.
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[int]
		$Depth = 2,

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
		$converter.MaxDepth = $Depth
		$converter.EnableVerbose = $EnableVerbose
		$converter.Config = $Configuration
		$converter.Cmdlet = $PSCmdlet
	}
	process {
		$converter.Convert($InputObject)
	}
}