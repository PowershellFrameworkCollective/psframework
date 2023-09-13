Import-Module PlatyPS -ErrorAction Stop
Import-Module "$PSScriptRoot\..\PSFramework\PSFramework.psd1" -Force -ErrorAction Stop
foreach ($file in Get-ChildItem -Path "$PSScriptRoot\..\help\en-us" -Filter *.md) {
	Update-MarkdownHelp -Path $file.FullName
}