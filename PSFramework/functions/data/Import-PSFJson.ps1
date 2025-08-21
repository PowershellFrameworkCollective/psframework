function Import-PSFJson {
	<#
	.SYNOPSIS
		Imports a json document from file and offers its content as objects.
		
	.DESCRIPTION
		Imports a json document from file and offers its content as objects.

		WARNING: The FixData parameter is experimental and may experience breaking changes!
	
	.PARAMETER Path
		Path to the file to import.
		Will evaluate wildcards.
	
	.PARAMETER LiteralPath
		Path to the file to import.
		Will NOT evaluate wildcards.
	
	.PARAMETER Encoding
		The encoding of the file to read.
		Defaults to UTF8.
	
	.PARAMETER AsHashtable
		Return content as hashtable, rather than PSCustomObject
	
	.PARAMETER FixData
		EXPERIMENTAL PARAMETER, MAY SUFFER BREAKING CHANGES
		Attempt to fix broken data from the data processed.
		Assumes the json was originally generated through PowerShell and tries to detect and fix issues that happened during export.
		Most notably: Timestamps no longer being proper timestamps.
	
	.EXAMPLE
		PS C:\> Import-PSFJson .\policies.json

		Reads the content of policies.json, parses its structure and returns objects representing its content.
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PSFFileLax]
		$Path,

		[PSFLiteralPath]
		$LiteralPath,

		[PSFArgumentCompleter('PSFramework-Encoding')]
		[PSFEncoding]
		$Encoding = 'UTF8',

		[switch]
		$AsHashtable,

		[switch]
		$FixData
	)
	begin {
		#region Functions
		function ConvertTo-Hashtable {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$InputObject
			)

			begin {
				$jsonTypes = @(
					'System.String'
					'System.Int32'
					'System.Int64'
					'System.Double'
					'System.Bool'
					'System.DateTime'
				)
			}
			process {
				$hashtable = $InputObject | ConvertTo-PSFHashtable
				foreach ($pair in $hashtable.GetEnumerator()) {
					if ($null -eq $pair.Value) { continue }
					if ($pair.Value.GetType().FullName -in $jsonTypes) { continue }
					if ($pair.Value -is [object[]]) {
						$pair.Value = foreach ($value in $pair.Value) {
							if ($null -eq $value) { $null; continue }
							if ($value.GetType().FullName -in $jsonTypes) { $value; continue }
							if ($value -is [object[]]) { $value; continue } # Accept not resolving double-nested arrays for simplicity
							ConvertTo-Hashtable -InputObject $value
						}
						continue
					}
					$pair.Value = ConvertTo-Hashtable -InputObject $pair.Value
				}
				$hashtable
			}
		}
		function Convert-JsonData {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipeline = $true)]
				$Data
			)

			begin {
				$jsonTypes = @(
					'System.String'
					'System.Int32'
					'System.Int64'
					'System.Double'
					'System.Bool'
					'System.DateTime'
				)
			}
			process {
				if ($null -eq $Data) { return }

				if ($Data -is [object[]]) {
					,@(ConvertFrom-JsonArray -Data $Data)
					return
				}

				if ($Data -is [hashtable]) { $properties = $Data.Keys }
				else { $properties = $Data.PSObject.Properties.Name }

				foreach ($property in $properties) {
					$item = $Data.$property
					if ($null -eq $item) { continue }
					if ($item -is [string] -and $item -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}\+\d{2}:\d{2}$') {
						$Data.$Property = $item -as [datetime]
						continue
					}
					if ($item.GetType().FullName -in $jsonTypes) { continue }
					if ($item -is [object[]]) {
						$Data.$property = @(ConvertFrom-JsonArray -Data $item)
						continue
					}
					
					# DateTime vNext
					if (
						$($item.PSObject.Properties).Count -eq 3 -and
						$item.PSObject.Properties.Name -contains 'value' -and
						$item.PSObject.Properties.Name -contains 'DisplayHint' -and
						$item.PSObject.Properties.Name -contains 'DateTime' -and
						$item.value -is [datetime]
					) {
						$Data.$property = $item.value
						continue
					}

					$Data.$property = Convert-JsonData -Data $item
				}

				$Data
			}
		}
		function ConvertFrom-JsonArray {
			[CmdletBinding()]
			param (
				$Data
			)

			$jsonTypes = @(
				'System.String'
				'System.Int32'
				'System.Double'
				'System.Bool'
				'System.DateTime'
			)

			foreach ($item in $Data) {
				if ($null -eq $item) { $null; continue }
				if ($item -is [string] -and $item -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{7}\+\d{2}:\d{2}$') {
					$item -as [datetime]
					continue
				}
				if ($item.GetType().FullName -in $jsonTypes) { $item; continue }
				if ($item -is [object[]]) { ,@(ConvertFrom-JsonArray -Data $item); continue }
				if (
					$item.PSObject.Properties.Count -eq 3 -and
					$item.PSObject.Properties.Name -contains 'value' -and
					$item.PSObject.Properties.Name -contains 'DisplayHint' -and
					$item.PSObject.Properties.Name -contains 'DateTime' -and
					$item.value -is [datetime]
				) {
					$item.value
					continue
				}
				Convert-JsonData -Data $item
			}
		}
		#endregion Functions
	}
	process {
		foreach ($entry in $Path.FailedInput) {
			Write-Error "Could not resolve as file: $entry"
		}

		foreach ($filePath in $Path + $LiteralPath) {
			$content = Get-PSFFileContent -LiteralPath $filePath -Encoding $Encoding
			if (-not $AsHashtable) { $data = $content | ConvertFrom-Json }
			else {
				if ($PSVersionTable.PSVersion.Major -gt 5) { $data = $content | ConvertFrom-Json -AsHashtable }
				else { $data = $content | ConvertFrom-Json | ConvertTo-Hashtable }
			}

			if (-not $FixData) {
				$data
				continue
			}

			# Fix Data (expensive)
			Convert-JsonData -Data $data
		}
	}
}