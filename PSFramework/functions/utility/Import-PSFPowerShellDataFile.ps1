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

	.PARAMETER Psd1Mode
		How psd1 files should be parsed.
		Available modes:
		- Classic: Only safe documents will be executed, and only the first hashtable will be processed.
          This option is only available on PowerShell v5 or later. In older versions, this mode is automatically
		  converted to "Safe"
	  	- Safe: Only safe documents without executable code are processed, but any number of hashtables
		  will be processed. At the root level of the document, only hashtables or an array containing only
		  hashtables may exist.
		- Unsafe: Psd1 file is basically processed as if it were a ps1 file.
		Both safe and unsafe modes respect Constrained Language Mode.

		Defaults to "Classic"

	.PARAMETER Unsafe
		This parameter has been deprecated and should no longer be used. Use "-Psd1Mode Unsafe" instead.
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
	[CmdletBinding(DefaultParameterSetName = 'ByPath')]
	Param (
		[Parameter(Position = 0, ParameterSetName = 'ByPath')]
		[string[]]
		$Path,
		
		[Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByLiteralPath')]
		[Alias('PSPath')]
		[string[]]
		$LiteralPath,

		[ValidateSet('Classic', 'Safe', 'Unsafe')]
		[string]
		$Psd1Mode = 'Classic',

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
		
		function Read-PowerShellDataFile {
			[CmdletBinding()]
			param (
				[string]
				$LiteralPath,

				[string]
				$Mode,

				$Cmdlet
			)

			$errors = $null
			$ast = [System.Management.Automation.Language.Parser]::ParseFile($LiteralPath, [ref] $null, [ref] $errors)

			if ($errors) {
				Stop-PSFFunction -String 'Import-PSFPowerShellDataFile.Error.Syntax' -StringValues $LiteralPath -EnableException $true -Cmdlet $Cmdlet -Target $LiteralPath
			}

			switch ($Mode) {
				'Classic' {
					$hashAst = $ast.Find({ $args[0] -is [System.Management.Automation.Language.HashtableAst] }, $false)
					if (-not $hashAst) {
						Write-PSFMessage -String 'Import-PSFPowerShellDataFile.Error.NoHashtable' -StringValues $LiteralPath
						Write-Error ((Get-PSFLocalizedString -Module PSFramework -Name 'Import-PSFPowerShellDataFile.Error.NoHashtable') -f $LiteralPath)
						return
					}
					try { $hashAst.SafeGetValue() }
					catch {
						Write-PSFMessage -String 'Import-PSFPowerShellDataFile.Error.Unsafe' -StringValues $LiteralPath -ErrorRecord $_
						$Cmdlet.WriteError($_)
					}
				}
				'Safe' {
					if (-not (Test-AstSafety -Ast $ast)) {
						Write-PSFMessage -String 'Import-PSFPowerShellDataFile.Error.Unsafe' -StringValues $LiteralPath
						Write-Error ((Get-PSFLocalizedString -Module PSFramework -Name 'Import-PSFPowerShellDataFile.Error.Unsafe') -f $LiteralPath)
						return
					}

					Invoke-UnsafeDocumentFile -Path $LiteralPath
				}
				'Unsafe' {
					Invoke-UnsafeDocumentFile -Path $LiteralPath
				}
			}
		}

		function Test-AstSafety {
			[OutputType([bool])]
			[CmdletBinding()]
			param (
				$Ast
			)

			$saveAstTypes = @(
				'ArrayExpressionAst'
				'CommandExpressionAst'
				'ConstantExpressionAst'
				'HashtableAst'
				'NamedBlockAst'
				'PipelineAst'
				'ScriptBlockAst'
				'StatementBlockAst'
				'StringConstantExpressionAst'
				'VariableExpressionAst'
			)

			$astElements = $Ast.FindAll({ $true }, $true)
			$groupedAstElements = $astElements | Group-Object { $_.GetType().Name }

			# Any not explicitly allowed AST elements are bad
			if ($groupedAstElements | Where-Object Name -NotIn $saveAstTypes) {
				return $false
			}

			# Some types are only allowed once
			$limited = @(
				'NamedBlockAst'
				'ScriptBlockAst'
			)
			if ($groupedAstElements | Where-Object { $_.Name -in $limited -and $_.Count -gt 1 }) {
				return $false
			}

			# The base Level may only contain hashtables, or a single array containing only hashtables
			$badStatements = $Ast.EndBlock.Statements | Where-Object {
				-not $_.PipelineElements -or
				$_.PipelineElements.Count -gt 2 -or
				$_.PipelineElements[0].Expression -isnot [System.Management.Automation.Language.HashtableAst]
			}

			if (
				$Ast.EndBlock.Statements.Count -eq 1 -and
				$Ast.EndBlock.Statements[0] -is [System.Management.Automation.Language.PipelineAst] -and
				$Ast.EndBlock.Statements[0].PipelineElements.Count -eq 1 -and
				$Ast.Endblock.Statements[0].PipelineElements[0] -is [System.Management.Automation.Language.CommandExpressionAst] -and
				$Ast.EndBlock.Statements[0].PipelineElements[0].Expression.GetType() -eq [System.Management.Automation.Language.ArrayExpressionAst]
			) {
				$arrayExpression = $Ast.EndBlock.Statements[0].PipelineElements[0].Expression
				$badStatements = $arrayExpression.SubExpression.Statements | Where-Object {
					$_ -isnot [System.Management.Automation.Language.PipelineAst] -or
					$_.PipelineElements.Count -gt 1 -or
					$_.PipelineElements[0].Expression -isnot [System.Management.Automation.Language.HashtableAst]
				}
			}

			if ($badStatements) { return $false }

			$true
		}

		function Invoke-UnsafeDocumentFile {
			[CmdletBinding()]
			param (
				[string]
				$Path
			)
			$filePath = Join-Path -Path (Get-PSFPath -Name Temp) -ChildPath "psf_temp-$(Get-Random).ps1"
			try {
				Copy-Item -LiteralPath $Path -Destination $filePath
				if ($PSVersionTable.PSVersion.Major -lt 5) {
					& $filePath
				}
				else {
					$scriptblock = [ScriptBlock]::Create("& `"$filePath`"")
					$executionContextInternal = [PSFramework.Utility.UtilityHost]::GetExecutionContextFromTLS()
					$everConstrained = [PSFramework.Utility.UtilityHost]::GetPrivateStaticProperty(
						$executionContextInternal.GetType(),
						"HasEverUsedConstrainedLanguage"
					)
					if ($everConstrained) {
						[PSFramework.Utility.UtilityHost]::SetPrivateProperty("LanguageMode", $scriptblock, [System.Management.Automation.PSLanguageMode]::ConstrainedLanguage)
					}
					$psfScript = [PsfScriptBlock]$scriptblock
					$psfScript.InvokeGlobal($null) | Write-Output
				}
			}
			finally {
				Remove-Item -Path $filePath -Force -ErrorAction Ignore
			}
		}
		#endregion Functions

		# If launched in JEA Endpoint, Import-PowerShellDataFile is unavailable due to a bug
		# It is important to check the initial sessionstate, as the module's current state will be 'FullLanguage' instead.
		# Import-PowerShellDataFile is also unavailable before PowerShell v5
		if ($Unsafe) { $Psd1Mode = 'Unsafe' }
		if (
			$Psd1Mode -eq 'Classic' -and
			(
				([runspace]::DefaultRunspace.InitialSessionState.LanguageMode -eq 'NoLanguage') -or
				($PSVersionTable.PSVersion.Major -lt 5)
			)
		) { $Psd1Mode = 'Safe' }
	}
	process {
		$resolvedPaths = $LiteralPath
		if ($Path) { $resolvedPaths = $Path | Resolve-PSFPath -Provider FileSystem | Sort-Object -Unique }

		foreach ($resolvedPath in $resolvedPaths) {
			$extension = ($resolvedPath -split "\.")[-1]
			switch ($extension) {
				#region Json
				{ $_ -in 'json', 'jsonc'} {
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
					Read-PowerShellDataFile -LiteralPath $resolvedPath -Mode $Psd1Mode -Cmdlet $PSCmdlet
				}
				#endregion Default / psd1
			}
		}
	}
}