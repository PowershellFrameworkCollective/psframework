function Export-PSFConfig
{
	[CmdletBinding()]
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
		$SkipUnchanged
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
				Stop-PSFFunction -Message "Could not export '$($item.FullName)': Data Type not supported" -Tag 'fail','export' -Continue
			}
			
			$resultantData[$item.FullName] = $item.RegistryData
		}
	}
	end
	{
		([pscustomobject]$resultantData) | ConvertTo-Json | Set-Content -Path $OutPath -Encoding UTF8
	}
}