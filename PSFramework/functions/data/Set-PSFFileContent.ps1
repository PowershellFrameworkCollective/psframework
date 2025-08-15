function Set-PSFFileContent {
	<#
	.SYNOPSIS
		Writes content to a file.
	
	.DESCRIPTION
		Writes content to a file.
		This is a replacement for Set-Content, trading flexibility in return for focus.

		Notably, it allows for consistent parameterization between PowerShell versions.
	
	.PARAMETER Path
		The file(s) to write to.
		Supports multiple files, at least the folder must exist.
	
	.PARAMETER InputObject
		The content to write.
		By default, this content will be converted to string and written as a line per object.
	
	.PARAMETER AsByteStream
		Instead of writing the content as a text file, write it as a binary blob.
		This requires the input to be valid bytes!
		Note: Writing binary filas via input from pipeline is SIGNIFICANTLY slower than providing the bytes as an explicitly bound parameter.
	
	.PARAMETER Encoding
		The encoding to write the text file in.
		Has no effect when using "-AsByteStream".
		Defaults to: UTF8 (with BOM).

	.PARAMETER NewLine
		The symbols to use as NewLine.
		The usual key consideration here is whether to include the carriage return (`r) or not.
		Defaults to: "`n"
		If you wish to include the carriage return, set it to "`r`n".
	
	.PARAMETER Append
		Whether to append your content to an existing file.
		Still creates the file, if it does not exist.
		By default, all previous content will be overwritten.
	
	.PARAMETER NoFlush
		Do not flush the contents of the files to disk, as you write them.
		By default, all contents - lines or bytes - are immediately written to disk ("Flushed"), to ensure no data is lost, in case of the pipeline failing.
		This increase in data assurance comes at an increased performance cost.
		Setting this parameter means it will only at the end, when all content has been sent, flush the contents to disk.
	
	.EXAMPLE
		PS C:\> Get-MgUser | ConvertTo-Json | Set-PSFFileContent -Path .\users.json

		Writes all users in the tenant as json to disk.

	.EXAMPLE
		PS C:\> $cert.GetRawCertData() | Set-PSFFileContent -Path .\cert.cer -AsByteStream

		Writes the raw certificate information as a .cer file to disk.
		This will result in a perfectly valid public certificate.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSFNewFile]
		$Path,

		[Parameter(ValueFromPipeline = $true)]
		[AllowEmptyString()]
		[object[]]
		$InputObject,

		[switch]
		$AsByteStream,

		[PSFArgumentCompleter('PSFramework-Encoding')]
		[PSFEncoding]
		$Encoding = 'UTF8',

		[string]
		$NewLine = "`n",

		[switch]
		$Append,

		[switch]
		$NoFlush
	)
	begin {
		$mode = 'Create'
		if ($Append) { $mode = 'OpenOrCreate' }
		
		try {
			$writers = foreach ($filePath in $Path) {
				$fileStream = [System.IO.FileStream]::new($filePath, $mode, 'ReadWrite', 'Read')
				if ($Append) { $fileStream.Position = $fileStream.Length }
				if ($AsByteStream) { $fileStream; continue }

				$writer = [System.IO.StreamWriter]::new($fileStream, $Encoding)
				if (-not $NoFlush) { $writer.AutoFlush = $true }
				$writer.NewLine = $NewLine
				$writer
			}
		}
		catch {
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
	process {
		if (-not $AsByteStream) {
			foreach ($inputItem in $InputObject) {
				foreach ($writer in $writers) {
					try { $writer.WriteLine($inputItem) }
					catch { $PSCmdlet.WriteError($_) }
				}
			}
		}
		else {
			try { $bytes = [byte[]]$InputObject }
			catch {
				Write-Error "Not a byte-array: $InputObject! Cannot write as byte-stream! $_" -TargetObject $InputObject
				return
			}
			foreach ($writer in $writers) {
				try { $writer.Write($bytes, 0, $bytes.Length) }
				catch { $PSCmdlet.WriteError($_) }
				if (-not $NoFlush) { $writer.Flush() }
			}
		}
	}
	end {
		foreach ($writer in $writers) {
			$writer.Flush()
			$writer.Close()
			$writer.Dispose()
		}
	}
}