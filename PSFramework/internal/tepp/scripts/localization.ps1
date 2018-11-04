Register-PSFTeppScriptblock -Name 'PSFramework-LanguageNames' -ScriptBlock {
	[System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name
}