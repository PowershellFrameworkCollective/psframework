function Import-PSFPowerShellDataFile
{
<#
	.SYNOPSIS
		A wrapper command around Import-PowerShellDataFile
	
	.DESCRIPTION
		A wrapper command around Import-PowerShellDataFile
		This enables use of the command on PowerShell 3+ as well as during JEA endpoints.
	
		Note: The protective value of Import-PowerShellDataFile is only offered when run on PS5+.
		This is merely meant to provide compatibility in the scenarios, where the original command would fail!
		If you care about PowerShell security, update to the latest version (in which case this command is still as secure as the default command, as that is what will actually be run.
	
	.PARAMETER Path
		The path from which to load the data file.
	
	.PARAMETER LiteralPath
		The path from which to load the data file.
		In opposite to the Path parameter, input here will not be interpreted.
	
	.EXAMPLE
		PS C:\> Import-PSFPowerShellDataFile -Path .\data.psd1
	
		Safely loads the data stored in data.psd1
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
		$LiteralPath
	)
	
	process
	{
		# If launched in JEA Endpoint, Import-PowerShellDataFile is unavailable due to a bug
		# It is important to check the initial sessionstate, as the module's current state will be 'FullLanguage' instead.
		# Import-PowerShellDataFile is also unavailable before PowerShell v5
		if (([runspace]::DefaultRunspace.InitialSessionState.LanguageMode -eq 'NoLanguage') -or ($PSVersionTable.PSVersion.Major -lt 5))
		{
			foreach ($resolvedPath in ($Path | Resolve-PSFPath -Provider FileSystem | Sort-Object -Unique))
			{
				Invoke-Expression (Get-Content -Path $resolvedPath -Raw)
			}
			foreach ($pathItem in $LiteralPath)
			{
				Invoke-Expression (Get-Content -Path $pathItem -Raw)
			}
		}
		else
		{
			Import-PowerShellDataFile @PSBoundParameters
		}
	}
}
