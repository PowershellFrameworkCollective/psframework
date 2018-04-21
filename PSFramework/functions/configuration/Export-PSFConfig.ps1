function Export-PSFConfig
{
<#
	.SYNOPSIS
		Exports configuration items to a Json file.
	
	.DESCRIPTION
		Exports configuration items to a Json file.
	
	.PARAMETER Config
		The configuration object(s) to export.
	
	.PARAMETER FullName
		Select the configuration objects to export by filtering by their full name.
	
	.PARAMETER Module
		Select the configuration objects to export by filtering by their module name.
	
	.PARAMETER Name
		Select the configuration objects to export by filtering by their name.
	
	.PARAMETER OutPath
		The path (filename included) to export to.
		Will fail if the folder does not exist, will overwrite the file if it exists.
	
	.PARAMETER SkipUnchanged
		If set, configuration objects whose value was not changed from its original value will not be exported.
		(Note: Settings that were updated with the same value as the original default will still be considered changed)
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Get-PSFConfig | Export-PSFConfig -OutPath '~/export.json'
	
		Exports all current settings to json.
	
	.EXAMPLE
		Export-PSFConfig -Module MyModule -OutPath '~/export.json' -SkipUnchanged
	
		Exports all settings of the module 'MyModule' that are no longer the original default values to json.
#>
	[CmdletBinding(DefaultParameterSetName = 'FullName')]
	Param (
		[Parameter(ParameterSetName = "Config", Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[Parameter(ParameterSetName = "FullName", Position = 0, Mandatory = $true)]
		[string]
		$FullName,
		
		[Parameter(ParameterSetName = "Module", Position = 0, Mandatory = $true)]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = "Module", Position = 1)]
		[string]
		$Name = "*",
		
		[Parameter(Position = 2, Mandatory = $true)]
		[string]
		$OutPath,
		
		[switch]
		$SkipUnchanged,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
		$resultantData = @{ }
	}
	process
	{
		if ($Config) { $items = $Config }
		if ($FullName) { $items = Get-PSFConfig -FullName $FullName }
		if ($Module) { $items = Get-PSFConfig -Module $Module -Name $Name }
		
		foreach ($item in $items)
		{
			if ($SkipUnchanged -and $item.Unchanged) { continue }
			
			if ($item.RegistryData -eq "<type not supported>")
			{
				Stop-PSFFunction -Message "Could not export '$($item.FullName)': Data Type not supported" -Tag 'fail','export' -Continue -EnableException $EnableException
			}
			
			$resultantData[$item.FullName] = $item.RegistryData
		}
	}
	end
	{
		try { ([pscustomobject]$resultantData) | ConvertTo-Json | Set-Content -Path $OutPath -Encoding UTF8 -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -Message "Failed to export to file" -EnableException $EnableException -ErrorRecord $_ -Tag 'fail', 'export'
			return
		}
	}
}