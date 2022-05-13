function Import-PSFPowerShellDataFile {
	<#
	.SYNOPSIS
		A wrapper command around Import-PowerShellDataFile
	
	.DESCRIPTION
		A wrapper command around Import-PowerShellDataFile
		This enables use of the command on PowerShell 3+ as well as during JEA endpoints.
	
		Note: The protective value of Import-PowerShellDataFile is only offered when run on PS5+.
		This is merely meant to provide compatibility in the scenarios, where the original command would fail!
		If you care about PowerShell security, update to the latest version (in which case this command is still as secure as the default command, as that is what will actually be run).

		Also supports importing Json files.
	
	.PARAMETER Path
		The path from which to load the data file.
	
	.PARAMETER LiteralPath
		The path from which to load the data file.
		In opposite to the Path parameter, input here will not be interpreted.

	.PARAMETER Unsafe
		Disables the protective value of Import-PowerShellDataFile.
		This effectively runs the provided powershell scriptfile as untrusted scriptfile, no matter the environment.
		By default, Import-PowerShellDataFile would only process the first hashtable, while unsafe mode allows files with multiple hashtables or more dynamic content.

		Note: In environments with tight security constraints, the file imported will be executed in constrained lnguage mode, even if the source file is trusted.
		Specifically, path-based rules will be ignored and .cab files will have no effect, but directly signed and trusted files will remain unconstrained.
	
	.EXAMPLE
		PS C:\> Import-PSFPowerShellDataFile -Path .\data.psd1
	
		Safely loads the data stored in data.psd1

	.EXAMPLE
		PS C:\> Import-PSFPowerShellDataFile -Path .\data.json
	
		Safely loads the data stored in data.json
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName = 'ByPath')]
		[string[]]
		$Path,
		
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByLiteralPath')]
		[Alias('PSPath')]
		[string[]]
		$LiteralPath,

		[switch]
		$Unsafe
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
					'System.Double'
					'System.Bool'
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
		#endregion Functions

		# If launched in JEA Endpoint, Import-PowerShellDataFile is unavailable due to a bug
		# It is important to check the initial sessionstate, as the module's current state will be 'FullLanguage' instead.
		# Import-PowerShellDataFile is also unavailable before PowerShell v5
		$backUpMode = $Unsafe -or ([runspace]::DefaultRunspace.InitialSessionState.LanguageMode -eq 'NoLanguage') -or ($PSVersionTable.PSVersion.Major -lt 5)
		
		if ($PSVersionTable.PSVersion.Major) {
			$executionContextInternal = [PSFramework.Utility.UtilityHost]::GetExecutionContextFromTLS()
			$everConstrained = [PSFramework.Utility.UtilityHost]::GetPrivateStaticProperty($executionContextInternal.GetType(), "HasEverUsedConstrainedLanguage")
		}
	}
	process {
		$resolvedPaths = $LiteralPath
		if ($Path) { $resolvedPaths = $Path | Resolve-PSFPath -Provider FileSystem | Sort-Object -Unique }

		foreach ($resolvedPath in $resolvedPaths) {
			$extension = ($resolvedPath -split "\.")[-1]
			switch ($extension) {
				#region Json
				json {
					if ($PSVersionTable.PSVersion.Major -gt 5) {
						$results = Get-Content -LiteralPath $resolvedPath | ConvertFrom-Json -AsHashtable
						$results
						break
					}

					$results = Get-Content -LiteralPath $resolvedPath | ConvertFrom-Json
					$results | ConvertTo-Hashtable
				}
				#endregion Json

				#region Default / psd1
				default {
					if ($backUpMode) {
						$filePath = Join-Path -Path (Get-PSFPath -Name Temp) -ChildPath "psf_temp-$(Get-Random).ps1"
						Copy-Item -LiteralPath $resolvedPath -Destination $filePath
						if ($PSVersionTable.PSVersion.Major -lt 5) {
							& $filePath
						}
						else {
							$scriptblock = [ScriptBlock]::Create("& `"$filePath`"")
							if ($everConstrained) {
								[PSFramework.Utility.UtilityHost]::SetPrivateProperty("LanguageMode", $scriptblock, [System.Management.Automation.PSLanguageMode]::ConstrainedLanguage)
							}
							$psfScript = [PsfScriptBlock]$scriptblock
							$psfScript.InvokeGlobal($null) | Write-Output
							# $psfScriptBlock.InvokeGlobal($null) | Write-Output
						}

						Remove-Item -Path $filePath
					}
					else { Import-PowerShellDataFile -LiteralPath $resolvedPath }
				}
				#endregion Default / psd1
			}
		}
	}
}