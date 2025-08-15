function Export-PSFJson {
	<#
	.SYNOPSIS
		Converts input to json string and writes the result to file.
	
	.DESCRIPTION
		Converts input to json string and writes the result to file.
		Uses ConvertTo-Json under the hood.

	.PARAMETER Path
		The path to the file(s) to create.
		The parent directory must exist, the file will be overwritten if it already does.
	
	.PARAMETER InputObject
		The data to convert to json and export.
	
	.PARAMETER Depth
		How deep the into sub-properties do we want to delve?
		Defaults to 2.
		Any nested sub-properties that are deeper than that many levels in will be lost in the result.
	
	.PARAMETER Compress
		Whether the Json string should be compressed to save space.
	
	.PARAMETER Encoding
		What encoding to write the file in.
		Defaults to UTF8 (with BOM).
	
	.EXAMPLE
		PS C:\> Get-MgUser | Export-PSFJson .\users.json
		
		Write all users from Microsoft Graph into a json file.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSFNewFile]
		$Path,

		[Parameter(ValueFromPipeline = $true)]
		$InputObject,

		[int]
		$Depth,

		[switch]
		$Compress,

		[PSFArgumentCompleter('PSFramework-Encoding')]
		[PSFEncoding]
		$Encoding = 'UTF8'
	)
	begin {
		$convertParam = @{ }
		if ($PSBoundParameters.Keys -contains 'Depth') { $convertParam.Depth = $Depth }
		if ($PSBoundParameters.Keys -contains 'Compress') { $convertParam.Compress = $Compress }
		$converter = { ConvertTo-Json @convertParam }.GetSteppablePipeline()

		# Only needed in END, but for propery validation we open it during begin
		$exporter = { Set-PSFFileContent -Path $Path -Encoding $Encoding }.GetSteppablePipeline()

		try { $converter.Begin($true) }
		catch { $PSCmdlet.ThrowTerminatingError($_) }

		try { $exporter.Begin($true) }
		catch { $PSCmdlet.ThrowTerminatingError($_) }
	}
	process {
		$converter.Process($InputObject)
	}
	end {
		$json = $converter.End()
		try { $exporter.Process($json) }
		catch { $PSCmdlet.WriteError($_) }

		$exporter.End()
	}
}