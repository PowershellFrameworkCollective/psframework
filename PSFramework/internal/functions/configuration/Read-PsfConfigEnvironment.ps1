function Read-PsfConfigEnvironment {
<#
	.SYNOPSIS
		Reads configuration settings from environment variables.
	
	.DESCRIPTION
		Reads configuration settings from environment variables.
		Returns objects with two properties: Name & Value
	
	.PARAMETER Prefix
		The prefix by which to filter environment variables.
		Only variables that start with the prefix, followeb by an underscore are processed.
	
	.PARAMETER Simple
		Whether to perform simple data processing.
		By default, the full configuration data format is expected.
	
	.EXAMPLE
		PS C:\> Read-PsfConfigEnvironment -Prefix PSFramework
	
		Loads all configuration settings provided by environment starting with PSFramework_.
		Will apply full configuration object parsing.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Prefix,
		
		[switch]
		$Simple
	)
	
	begin {
		function ConvertFrom-EnvironmentSetting {
			[CmdletBinding()]
			param (
				[Parameter(ValueFromPipelineByPropertyName = $true)]
				[string]
				$Name,
				
				[Parameter(ValueFromPipelineByPropertyName = $true)]
				[string]
				$Value,
				
				[bool]
				$Simple,
				
				[string]
				$Prefix
			)
			
			process {
				#region Common Mode
				if (-not $Simple) {
					try {
						[pscustomobject]@{
							FullName = $Name.SubString(($Prefix.Length + 1))
							Value = [PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($Value)
						}
					}
					catch {
						Write-PSFMessage -Level Warning -String 'Read-PsfConfigEnvironment.BadData' -StringValues $Name, $Value
					}
				}
				#endregion Common Mode
				#region Simple Mode
				else {
					$fullName = $Name.SubString(($Prefix.Length + 1))
					if ($Value -eq '') { return [PSCustomObject]@{ FullName = $fullName; Value = $null } }
					if ($Value -eq 'true') { return [PSCustomObject]@{ FullName = $fullName; Value = $true } }
					if ($Value -eq 'false') { return [PSCustomObject]@{ FullName = $fullName; Value = $false } }
					$tempVal = $null
					if ([int32]::TryParse($Value, [ref]$tempVal)) {
						return [PSCustomObject]@{ FullName = $fullName; Value = $tempVal }
					}
					$tempVal = $null
					if ([int64]::TryParse($Value, [ref]$tempVal)) {
						return [PSCustomObject]@{ FullName = $fullName; Value = $tempVal }
					}
					$tempVal = $null
					if ([double]::TryParse($Value, 'Any', [System.Globalization.NumberFormatInfo]::InvariantInfo, [ref]$tempVal)) {
						return [PSCustomObject]@{ FullName = $fullName; Value = $tempVal }
					}
					$tempVal = $null
					if ([datetime]::TryParse($Value, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, 'AssumeUniversal', [ref]$tempVal)) {
						return [PSCustomObject]@{ FullName = $fullName; Value = $tempVal }
					}
					if ($Value -match "^.|*") {
						return [PSCustomObject]@{ FullName = $fullName; Value = $Value.SubString(2).Split($Value.Substring(0, 1)) }
					}
					return [PSCustomObject]@{ FullName = $fullName; Value = $Value }
				}
				#endregion Simple Mode
			}
		}
	}
	process {
		Get-ChildItem "env:$($Prefix)_*" | ConvertFrom-EnvironmentSetting -Simple $Simple -Prefix $Prefix
	}
}