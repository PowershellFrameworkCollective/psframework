function Import-PSFLocalizedString
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
		PS C:\> Import-PSFLocalizedString -Path '$moduleRoot\strings.psd1' -Module 'MyModule'
	
		Improts the strigns stored in strings.psd1 for the module MyModule as 'en-US' language strings.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Module,
		
		[PsfValidateSet(TabCompletion = 'PSFramework-LanguageNames')]
		[string]
		$Language = 'en-US'
	)
	
	begin
	{
		try { $resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem -SingleItem }
		catch { Stop-PSFFunction -Message "Failed to resolve path: $Path" -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ }
	}
	process
	{
		$data = Import-PowerShellDataFile -Path $resolvedPath
		foreach ($key in $data.Keys)
		{
			[PSFramework.Localization.LocalizationHost]::Write($Module, $key, $Language, $data[$key])
		}
	}
	end
	{
	
	}
}