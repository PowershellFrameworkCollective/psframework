function Get-PSFFileContent {
	<#
	.SYNOPSIS
		Read the contents of a file.
	
	.DESCRIPTION
		Read the contents of a file.
		This is a replacement for Get-Content, trading flexibility in return for focus.

		Notably, it allows for consistent parameterization between PowerShell versions.
	
	.PARAMETER Path
		Path to the file(s) to read.
	
	.PARAMETER LiteralPath
		Literal Path to the file(s) to read.
		This does NOT use wildcard expressions when evaluating paths.
	
	.PARAMETER ReadCount
		How man lines to include in a single return / dataset.
		Set to 0 or less to return the entire file as a single string.
		Example: When reading a file with 13 lines of text, setting "ReadCount" to 5 will return 3 strings: 2 strings of 5 lines each, one with the remaining 3.
		Defaults to: 1
	
	.PARAMETER TotalCount
		How many datasets in total to return.
		When specified, this allows limiting the returned amount of results.
		This parameter takes ReadCount into account, not counting individual lines of text, but number of result-sets after considering ReadCount.
		
		Example 1: File: 50 Lines, ReadCount: 1, TotalCount: 20
		In this case, the first 20 lines of the text file are returned

		Example 2: File: 50 Lines, ReadCount: 3, TotalCount: 10
		In this case, the first 10 results of 3-line strings are returned (resulting in 10 strings, covering a total of 30 lines of the text file).
	
	.PARAMETER Skip
		How many dataset to skip.
		The size of a dataset depends on the ReadCount parameter.
		Skips the first X datasets, unless combined with "Last", in which case it will skip the last X datasets instead.
	
	.PARAMETER Last
		Only return the last X datasets from the file.
		The size of a dataset depends on the ReadCount parameter.
	
	.PARAMETER AsByteStream
		Return the content of the file as a binary stream.
		This parameter changes the behavior of many other parameters, as it is not compatible with "-ReadCount".
		Each dataset is now always a single byte.

		Example: TotalCount: 48, Skip: 12
		In this example, it will skip the first 12 bytes in the file and then return the next 48 (or less, if there are fewer bytes in the file in total).
	
	.PARAMETER Wait
		Rather than execute the command and then return, wait for some time and keep looking for new entries to be added to the file.
		This will return new lines / datasets as they are added to the file.
		This command will look every second for new content in the file.
	
	.PARAMETER Timeout
		The amount of time to wait before stopping waiting for new content in the file.
		Defaults to: 1 hour.
	
	.PARAMETER Encoding
		The encoding to interpret the text file under.
		Has no effect when using "-AsByteStream".
		Defaults to: UTF8 (with BOM).

	.EXAMPLE
		PS C:\> Get-PSFFileContent .\response.json | ConvertFrom-Json

		Read a json file and convert into useful objects.

	.EXAMPLE
		PS C:\> Get-PSFFileContent .\service-2025-08-14.log -Last 20 -Wait

		Read the last 20 lines in the specified logfile, then wait for more lines as they are written to the file.
	
	.EXAMPLE
		PS C:\> $certBytes = Get-PSFFileContent -Path .\cert.cer -AsByteStream

		Reads the bytes from the specified certificate file.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding(DefaultParameterSetName = 'Text')]
	param (
		[Parameter(Position = 0, ValueFromPipeline = $true)]
		[PSFFile]
		$Path,

		[PSFLiteralPath]
		$LiteralPath,

		[Parameter(ParameterSetName = 'Text')]
		[long]
		$ReadCount = 1,

		[long]
		$TotalCount,

		[long]
		$Skip,

		[long]
		$Last,

		[Parameter(Mandatory = $true, ParameterSetName = 'Bytes')]
		[switch]
		$AsByteStream,

		[switch]
		$Wait,

		[PSFTimeSpan]
		$Timeout = '1h',

		[Parameter(ParameterSetName = 'Text')]
		[PSFArgumentCompleter('PSFramework-Encoding')]
		[PSFEncoding]
		$Encoding = 'UTF8'
	)
	begin {
		#region Utility Functions
		function Read-Stream {
			[CmdletBinding()]
			param (
				[System.IO.StreamReader]
				$Reader,

				[int]
				$ReadCount,

				[int]
				$Count,

				[switch]
				$All,

				[hashtable]
				$Counter = @{ Total = 0 }
			)

			$currentCount = 0
			while (
				-not $Reader.EndOfStream -and
				(
					($Count -lt 1) -or
					($currentCount -lt $Count)
				) -and
				(
					(-not $Counter.Limit) -or
					($Counter.Limit -lt 1) -or
					($Counter.Limit -gt $Counter.Total)
				)
			) {
				$lines = foreach ($index in 1..$ReadCount) {
					if (-not $Reader.EndOfStream) { $Reader.ReadLine() }
				}
				$lines -join "`n"
				$currentCount++
				$Counter.Total++

				if (-not $All -and $PSBoundParameters.Keys -notcontains 'Count') { break }
			}
		}
		#endregion Utility Functions

		$first = $true
	}
	process {
		if ($first) {
			$files = $Path + $LiteralPath | Remove-PSFNull
			$first = $false
		}
		else { $files = $Path }

		:main foreach ($filePath in $files) {
			#region Binary Read
			if ($AsByteStream) {
				try { $fileStream = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]'ReadWrite, Delete')) }
				catch {
					$PSCmdlet.WriteError($_)
					continue
				}

				$start = 0
				$end = $fileStream.Length
				if ($PSBoundParameters.Keys -contains 'Last') {
					$start = $end - $Last
					if ($Skip -gt 0) {
						$start = $start - $Skip
						$end = $end - $Skip
					}
				}
				elseif ($PSBoundParameters.Keys -contains 'TotalCount') {
					$end = $start + $TotalCount
					if ($Skip -gt 0) {
						$start = $start + $Skip
						$end = $end + $Skip
					}
				}
				if ($start -lt 0) { $start = 0 }
				if ($end -gt $fileStream.Length) { $end = $fileStream.Length }
				if ($start -eq $end) { continue }

				$length = $end - $start

				$buffer = [byte[]]::new($length)
				
				try {
					$fileStream.Position = $Start
					$null = $fileStream.Read($buffer, 0, $Length)
					, $buffer
				}
				catch { $PSCmdlet.WriteError($_) }
				finally {
					$fileStream.Close()
					$fileStream.Dispose()
				}

				continue
			}
			#endregion Binary Read

			#region Text Read
			try { $fileStream = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, ([System.IO.FileShare]'ReadWrite, Delete')) }
			catch {
				$PSCmdlet.WriteError($_)
				continue
			}
			$reader = [System.IO.StreamReader]::new($fileStream, $Encoding)
			
			try {
				if ($PSBoundParameters.Keys -contains 'Last') {
					$lines = [PSFramework.Utility.LimitedConcurrentQueue[string]]::new(($Last + $Skip))
					foreach ($result in Read-Stream -Reader $reader -ReadCount $ReadCount -All) {
						$lines.Enqueue($result)
					}
					$total = $Last - ($lines.Size - $lines.Count)
					# We skipped more than we had
					if ($total -lt 1) { continue main }

					@($($lines))[0..($total - 1)]
				}
				
				if ($Skip -gt 1) {
					$null = Read-Stream -Reader $reader -ReadCount $ReadCount -Count $Skip
				}
				if ($reader.EndOfStream -and -not $Wait) { continue main }

				$counter = @{
					Total = 0
					Limit = $TotalCount
				}
				
				if (-not $reader.EndOfStream) {
					if ($ReadCount -lt 1) {
						$reader.ReadToEnd().Trim("`n`r")
						if (-not $Wait) { continue main }
					}
					else {
						Read-Stream -Reader $reader -ReadCount $ReadCount -All -Counter $counter
					}
				}

				if (-not $Wait) { continue main }

				$start = Get-Date
				$timeLimit = $start.Add($Timeout)

				while (
					(
						($TotalCount -le 0) -or
						($counter.Total -lt $counter.Limit)
					) -and
					(([datetime]::Now) -lt $timeLimit)
				) {
					if (-not $reader.EndOfStream) {
						Read-Stream -Reader $reader -ReadCount $ReadCount -All -Counter $counter
					}
					Start-Sleep -Seconds 1
				}
			}
			catch {
				$PSCmdlet.WriteError($_)
			}
			finally {
				$fileStream.Close()
				$fileStream.Dispose()
			}
			#endregion Text Read
		}
	}
}