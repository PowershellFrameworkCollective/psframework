function Import-PSFConfig
{
<#
	.SYNOPSIS
		Imports a json configuration file into the configuration system.
	
	.DESCRIPTION
		Imports a json configuration file into the configuration system.
	
	.PARAMETER Path
		The path to the json file to import.
	
	.PARAMETER IncludeFilter
		If specified, only elements with names that are similar (-like) to names in this list will be imported.
	
	.PARAMETER ExcludeFilter
		Elements that are similar (-like) to names in this list will not be imported.
	
	.PARAMETER Peek
		Rather than applying the setting, return the configuration items that would have been applied.
	
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
		
		[string[]]
		$IncludeFilter,
		
		[string[]]
		$ExcludeFilter,
		
		[switch]
		$Peek,
		
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
			
			:element foreach ($element in $data)
			{
				#region Exclude Filter
				foreach ($exclusion in $ExcludeFilter)
				{
					if ($element.FullName -like $exclusion)
					{
						continue element
					}
				}
				#endregion Exclude Filter
				
				#region Include Filter
				if ($IncludeFilter)
				{
					$isIncluded = $false
					foreach ($inclusion in $IncludeFilter)
					{
						if ($element.FullName -like $inclusion)
						{
							$isIncluded = $true
							break
						}
					}
					
					if (-not $isIncluded) { continue }
				}
				#endregion Include Filter
				
				if ($Peek) { $element }
				else
				{
					try { Set-PSFConfig -FullName $element.FullName -Value (Convert-PsfConfigValue -Value ("{0}:{1}" -f $element.Type, $element.Value)) }
					catch
					{
						Stop-PSFFunction -Message "Failed to set '$($element.FullName)'" -ErrorRecord $_ -EnableException $EnableException -Tag 'fail', 'import' -Continue -Target $item
					}
				}
			}
		}
	}
	end
	{
	
	}
}