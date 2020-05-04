function Test-PSFLanguageMode
{
<#
	.SYNOPSIS
		Tests, in what language mode a specified scriptblock is in.
	
	.DESCRIPTION
		Tests, in what language mode a specified scriptblock is in.
		Use this to determine the trustworthyness of a scriptblock, or for insights, into what its capabilities are.
	
	.PARAMETER ScriptBlock
		The scriptblock to test.
	
	.PARAMETER Mode
		The Languagemode(s) to compare it to.
		The scriptblock must be in one of the specified modes.
		Defaults to 'FullLanguage'
	
	.PARAMETER Not
		Reverses the test results - now the scriptblock may NOT be in one of the specified language modes.
	
	.EXAMPLE
		PS C:\> Test-PSFLanguageMode -ScriptBlock $ScriptBlock
	
		Returns, whether the $Scriptblock is in FullLanguage mode.
	
	.EXAMPLE
		PS C:\> Test-PSFLanguageMode -ScriptBlock $code -Mode ConstrainedLanguage -Not
	
		Returns $true if the specified scriptblock is NOT inconstrained language mode.
#>
	[OutputType([boolean])]
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$ScriptBlock,
		
		[System.Management.Automation.PSLanguageMode[]]
		$Mode = 'FullLanguage',
		
		[switch]
		$Not
	)
	
	process
	{
		$languageMode = [PSFramework.Utility.UtilityHost]::GetPrivateProperty("LanguageMode", $ScriptBlock)
		if ($Not) { $languageMode -notin $Mode }
		else { $languageMode -in $Mode }
	}
}