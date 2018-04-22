function Import-PSFConfig
{
<#
	.SYNOPSIS
		Imports a json configuration file into the configuration system.
	
	.DESCRIPTION
		Imports a json configuration file into the configuration system.
	
	.PARAMETER Path
		The path to the json file to import.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Import-PSFConfig -Path '.\config.json'
	
		Imports the configuration stored in '.\config.json'
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[PsfValidateScript({ Test-Path $args[0] }, ErrorMessage = "Could not validate path. Make sure the file {0} exists!")]
		[string[]]
		$Path,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug','start','param'
	}
	process
	{
		foreach ($item in $Path)
		{
			try { $data = Get-Content -Path $item -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
			catch { Stop-PSFFunction -Message "Failed to import $item" -EnableException $EnableException -Tag 'fail', 'import' -ErrorRecord $_ -Continue -Target $item }
			
			foreach ($element in $data)
			{
				try { Set-PSFConfig -FullName $element.FullName -Value (Convert-PsfConfigValue -Value ("{0}:{1}" -f $element.Type, $element.Value)) }
				catch
				{
					Stop-PSFFunction -Message "Failed to set '$($property.Name)'" -ErrorRecord $_ -EnableException $EnableException -Tag 'fail','import' -Continue -Target $item
				}
			}
		}
	}
	end
	{
	
	}
}