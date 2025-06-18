Import-Module PlatyPS -ErrorAction Stop
Import-Module "$PSScriptRoot\..\PSFramework\PSFramework.psd1" -Force -ErrorAction Stop

$helpRoot = "$PSScriptRoot\..\help\en-us"

foreach ($file in Get-ChildItem -Path $helpRoot -Filter *.md) {
	Update-MarkdownHelp -Path $file.FullName
}
foreach ($command in Get-Command -Module PSFramework -CommandType Cmdlet) {
	if (Test-Path -Path "$helpRoot\$($command.Name).md") { continue }
	New-MarkdownHelp -Command $command.Name -OutputFolder $helpRoot
}