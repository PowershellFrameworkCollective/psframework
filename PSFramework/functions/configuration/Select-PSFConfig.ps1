function Select-PSFConfig
{
<#
	.SYNOPSIS
		Select a subset of configuration entries and return them as objects.
	
	.DESCRIPTION
		Select a subset of configuration entries and return them as objects.
		
		This can be used to retrieve related configuration entries as a single PowerShell object.
		
		For example, assuming there are the following configuration entries:
		
		LoggingProvider.LogFile.AutoInstall
		LoggingProvider.LogFile.Enabled
		LoggingProvider.LogFile.ExcludeModules
		LoggingProvider.LogFile.ExcludeTags
		LoggingProvider.LogFile.IncludeModules
		LoggingProvider.LogFile.IncludeTags
		LoggingProvider.LogFile.InstallOptional
		
		Then this line:
		Select-PSFConfig 'LoggingProvider.LogFile.*'
		
		Will return a PSCustomObject that looks similar to this:
		
		_Name           : LogFile
		_FullName       : LoggingProvider.LogFile
		_Depth          : 1
		_Children       : {}
		AutoInstall     : False
		Enabled         : False
		ExcludeModules  : {}
		ExcludeTags     : {}
		IncludeModules  : {}
		IncludeTags     : {}
		InstallOptional : True
		
		This selection is recursive:
		It will group on each part of the FullName of the selected configuration entries.
		- Entries that only have children and no straight values (In the example above, that would be the first, the "LoggingProvider" node) will not be included and only return children.
		- Entries with values AND children, will have child entries included in the _Children property.
		- Even child entries of Entries with values will be returned
	
	.PARAMETER FullName
		String filter to select, which configuration entries to select on.
		Use the same value on Get-PSFConfig to see what configuration entries will be processed.
	
	.PARAMETER Depth
		Only entries at the specified depth level will be returned.
		Depth starts at "0"
		In the name 'LoggingProvider.LogFile.AutoInstall' ...
	
		- "LoggingProvider" would be depth 0
		- "LogFile" would be depth 1
		- ...
	
	.EXAMPLE
		PS C:\> Select-PSFConfig 'LoggingProvider.LogFile.*'
	
		Selects all configuration settings under 'LoggingProvider.LogFile.*', grouping the value ends as PSObject.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	param (
		[Alias('Name')]
		[string]
		$FullName,
		
		[int[]]
		$Depth
	)
	
	begin
	{
		function Group-Config
		{
			[CmdletBinding()]
			param (
				$Config,
				
				[int]
				$Depth
			)
			
			$grouped = $Config | Group-Object { $_.FullName.Split('.')[$Depth] }
			foreach ($group in $grouped)
			{
				if (-not $group.Name) { continue }
				$data = [ordered]@{
					_Name = $group.Name
					_FullName = $group.Group[0].FullName.Split('.')[0..($Depth)] -join "."
					_Depth = $Depth
					_Children = @()
				}
				if ($subGroups = $group.Group | Where-Object { $_.FullName.Split(".").Count -gt ($Depth + 2) })
				{
					$data._Children = Group-Config -Config $subGroups -Depth ($Depth + 1)
					$data._Children
				}
				
				foreach ($cfgItem in ($group.Group | Where-Object { $_.FullName.Split(".").Count -eq ($Depth + 2) }))
				{
					$cfgName = $cfgItem.FullName -replace "^([^\.]+\.){0,$($Depth + 1)}"
					$data[$cfgName] = $cfgItem.Value
				}
				if ($data.Keys.Count -gt 4) { [PSCustomObject]$data }
			}
		}
	}
	process
	{
		$configItems = Get-PSFConfig -FullName $FullName
		Group-Config -Config $configItems -Depth 0 | ForEach-Object {
			if (-not $Depth) { return $_ }
			if ($_._Depth -in $Depth) { $_ }
		}
	}
}