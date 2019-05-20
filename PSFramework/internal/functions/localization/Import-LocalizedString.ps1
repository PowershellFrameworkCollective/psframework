function Import-LocalizedString
{
<#
	.SYNOPSIS
		Imports a set of localized strings from a PowerShell data file.
	
	.DESCRIPTION
		Imports a set of localized strings from a PowerShell data file.
		This is used to feed the localized string feature set.
		Always import for all languages, do not select by current language - the system handles language selection.
	
		Strings are process wide, so loading additional languages can be offloaded into a background task.
	
	.PARAMETER Path
		The path to the psd1 file to import as strings file.
	
	.PARAMETER Module
		The module for which to import the strings.
	
	.PARAMETER Language
		The language of the specific strings file.
		Defaults to en-US.
	
	.EXAMPLE
		PS C:\> Import-LocalizedString -Path '$moduleRoot\strings.psd1' -Module 'MyModule'
	
		Imports the strings stored in strings.psd1 for the module MyModule as 'en-US' language strings.
#>
	[PSFramework.PSFCore.NoJeaCommand()]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Module,
		
		[string]
		$Language = 'en-US'
	)
	
	begin
	{
		try { $resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem }
		catch { Stop-PSFFunction -Message "Failed to resolve path: $Path" -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ }
	}
	process
	{
		foreach ($pathItem in $resolvedPath)
		{
			# If launched in JEA Endpoint, Import-PowerShellDataFile is unavailable due to a bug
			# It is important to check the initial sessionstate, as the module's current state will be 'FullLanguage' instead.
			if ($ExecutionContext.Host.Runspace.InitialSessionState.LanguageMode -eq 'NoLanguage')
			{
				# This is considered safe, as you should not be using unsafe localization resources in a constrained endpoint
				$data = Invoke-Expression (Get-Content -Path $pathItem -Raw)
			}
			else
			{
				$data = Import-PowerShellDataFile -Path $pathItem
			}
			foreach ($key in $data.Keys)
			{
				[PSFramework.Localization.LocalizationHost]::Write($Module, $key, $Language, $data[$key])
			}
		}
	}
}