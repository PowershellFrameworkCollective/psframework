function Register-PSFTypeSerializationData
{
<#
	.SYNOPSIS
		Registers serialization xml Typedata.
	
	.DESCRIPTION
		Registers serialization xml Typedata.
		Use Get-PSFTypeSerializationData to generate such a string.
		When building a module, consider shipping that xml type extension in a dedicated file as part of the module and import it as part of the manifest's 'TypesToProcess' node.
	
	.PARAMETER TypeData
		The data to register.
		Generate with Get-PSFTypeSerializationData.
	
	.PARAMETER Path
		Where the file should be stored before appending.
		While type extensions can be added at runtime directly from memory, from file is more reliable.
		By default, a PSFramework path is chosen.
		The default path can be configured under the 'PSFramework.Serialization.WorkingDirectory' confguration setting.
	
	.EXAMPLE
		PS C:\> Get-PSFTypeSerializationData -InputObject 'My.Custom.Type' | Register-PSFTypeSerializationData
	
		Generates a custom type serialization xml and registers it.
#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFTypeSerializationData')]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[string[]]
		$TypeData,
		
		[string]
		$Path = (Get-PSFConfigValue -FullName 'PSFramework.Serialization.WorkingDirectory' -Fallback $script:path_typedata)
	)
	
	begin
	{
		if (-not (Test-Path $Path -PathType Container))
		{
			$null = New-Item -Path $Path -ItemType Directory -Force
		}
	}
	process
	{
		foreach ($item in $TypeData)
		{
			$name = $item -split "`n" | Select-String "<Name>(.*?)</Name>" | Where-Object { $_ -notmatch "<Name>Deserialized.|<Name>PSStandardMembers</Name>|<Name>SerializationData</Name>" } | Select-Object -First 1 | ForEach-Object { $_.Matches[0].Groups[1].Value }
			$fullName = Join-Path $Path.Trim "$($name).Types.ps1xml"
			
			$item | Set-Content -Path $fullName -Force -Encoding UTF8
			Update-TypeData -AppendPath $fullName
		}
	}
}