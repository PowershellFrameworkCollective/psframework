function New-PSFTempFile
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[PsfValidateScript('PSFramework.Validate.SafeName', ErrorString = 'PSFramework.Validate.SafeName')]
		[string]
		$Name,

		[string]
		$Extension = 'tmp',

		[PSFDateTime]
		$Timeout,

		[string]
		$ModuleName
	)
	
	begin
	{
		$tempPath = Get-PSFPath -Name Temp
	}
	process
	{
		$newPath = Join-Path -Path $tempPath -ChildPath "PSF_Temp_$(New-Guid).$($Extension)"
		$tempItem = [PSFramework.Temp.TempFile]::new($Name, $ModuleName, $newPath, $script:tempItems)
		if ($Timeout) { $tempItem.Timeout = $Timeout }
	}
}
