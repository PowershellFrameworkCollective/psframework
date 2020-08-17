Register-PSFTeppScriptblock -Name "PSFramework-Encoding" -ScriptBlock {
	'Unicode'
	'BigEndianUnicode'
	'UTF8'
	'UTF8Bom'
	'UTF8NoBom'
	'UTF7'
	'UTF32'
	'Ascii'
	'Default'
	'BigEndianUTF32'
	if (Get-PSFConfigValue -FullName 'PSFramework.Text.Encoding.FullTabCompletion')
	{
		[System.Text.Encoding]::GetEncodings().BodyName
	}
} -Global