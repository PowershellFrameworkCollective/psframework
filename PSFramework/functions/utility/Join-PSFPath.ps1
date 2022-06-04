function Join-PSFPath
{
<#
    .SYNOPSIS
        Performs multisegment path joins.
    
    .DESCRIPTION
        Performs multisegment path joins.
    
    .PARAMETER Path
        The basepath to join on.
    
    .PARAMETER Child
        Any number of child paths to add.
	
	.PARAMETER Normalize
		Normalizes path separators for the path segments offered.
		This ensures the correct path separators for the current OS are chosen.
    
    .EXAMPLE
        PS C:\> Join-PSFPath -Path 'C:\temp' 'Foo' 'Bar'
    
        Returns 'C:\temp\Foo\Bar'
	
	.EXAMPLE
		PS C:\> Join-PSFPath -Path 'C:\temp' 'Foo' 'Bar' -Normalize
    
        Returns 'C:\temp\Foo\Bar' on a Windows OS.
		Returns 'C:/temp/Foo/Bar' on most non-Windows OSes.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Path,
		
		[Parameter(ValueFromRemainingArguments = $true)]
		[Alias('ChildPath')]
		[string[]]
		$Child,
		
		[switch]
		$Normalize
	)
	
	process
	{
		$resultingPath = $Path
		
		foreach ($childItem in $Child)
		{
			$resultingPath = Join-Path -Path $resultingPath -ChildPath $childItem
		}
		
		if ($Normalize)
		{
			$defaultSeparator = [System.IO.Path]::DirectorySeparatorChar
			$altSeparator = [System.IO.Path]::AltDirectorySeparatorChar
            # Alt Directory Separator Char is not reliable on all platforms
            if ($defaultSeparator -eq $altSeparator)
            {
                if ($defaultSeparator -eq '\') { $altSeparator = '/' }
                else { $altSeparator = '\' }
            }
			$resultingPath = $resultingPath.Replace($altSeparator, $defaultSeparator)
		}
		
		$resultingPath
	}
}