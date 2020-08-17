function Export-PSFConfig
{
<#
	.SYNOPSIS
		Exports configuration items to a Json file.
	
	.DESCRIPTION
		Exports configuration items to a Json file.
	
	.PARAMETER FullName
		Select the configuration objects to export by filtering by their full name.
	
	.PARAMETER Module
		Select the configuration objects to export by filtering by their module name.
	
	.PARAMETER Name
		Select the configuration objects to export by filtering by their name.
	
	.PARAMETER Config
		The configuration object(s) to export.
		Returned by Get-PSFConfig.
	
	.PARAMETER ModuleName
		Exports all configuration pertinent to a module to a predefined path.
		Exported configuration items include all settings marked as 'ModuleExport' that have been changed from the default value.
	
	.PARAMETER ModuleVersion
		The configuration version of the module-settings to write.
	
	.PARAMETER Scope
		Which predefined path to write module specific settings to.
		Only file scopes are considered.
		By default it writes to the suer profile.
	
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
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'FullName', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Export-PSFConfig')]
	param (
		[Parameter(ParameterSetName = "FullName", Position = 0, Mandatory = $true)]
		[string]
		$FullName,
		
		[Parameter(ParameterSetName = "Module", Position = 0, Mandatory = $true)]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = "Module", Position = 1)]
		[string]
		$Name = "*",
		
		[Parameter(ParameterSetName = "Config", Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[Parameter(ParameterSetName = "ModuleName", Mandatory = $true)]
		[string]
		$ModuleName,
		
		[Parameter(ParameterSetName = "ModuleName")]
		[int]
		$ModuleVersion = 1,
		
		[Parameter(ParameterSetName = "ModuleName")]
		[PSFramework.Configuration.ConfigScope]
		$Scope = "FileUserShared",
		
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'Config')]
		[Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'FullName')]
		[Parameter(Position = 2, Mandatory = $true, ParameterSetName = 'Module')]
		[string]
		$OutPath,
		
		[switch]
		$SkipUnchanged,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		$items = @()
		
		# Values 1, 2, 4 and 8 represent the four registry locations
		if (($Scope -band 15) -and $ModuleName)
		{
			Stop-PSFFunction -String 'Export-PSFConfig.ToRegistry' -EnableException $EnableException -Category InvalidArgument -Tag 'fail', 'scope', 'registry'
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not $ModuleName)
		{
			foreach ($item in $Config) { $items += $item }
			if ($FullName) { $items = Get-PSFConfig -FullName $FullName }
			if ($Module) { $items = Get-PSFConfig -Module $Module -Name $Name }
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not $ModuleName)
		{
			try { Write-PsfConfigFile -Config ($items | Where-Object { -not $SkipUnchanged -or -not $_.Unchanged }) -Path $OutPath -Replace }
			catch
			{
				Stop-PSFFunction -String 'Export-PSFConfig.Write.Error' -EnableException $EnableException -ErrorRecord $_ -Tag 'fail', 'export'
				return
			}
		}
		else
		{
			if ($Scope -band 16) # File: User Local
			{
				Write-PsfConfigFile -Config (Get-PSFConfig -Module $ModuleName -Force | Where-Object ModuleExport | Where-Object Unchanged -NE $true) -Path (Join-Path $script:path_FileUserLocal "$($ModuleName.ToLower())-$($ModuleVersion).json")
			}
			if ($Scope -band 32) # File: User Shared
			{
				Write-PsfConfigFile -Config (Get-PSFConfig -Module $ModuleName -Force | Where-Object ModuleExport | Where-Object Unchanged -NE $true) -Path (Join-Path $script:path_FileUserShared "$($ModuleName.ToLower())-$($ModuleVersion).json")
			}
			if ($Scope -band 64) # File: System-Wide
			{
				Write-PsfConfigFile -Config (Get-PSFConfig -Module $ModuleName -Force | Where-Object ModuleExport | Where-Object Unchanged -NE $true) -Path (Join-Path $script:path_FileSystem "$($ModuleName.ToLower())-$($ModuleVersion).json")
			}
		}
	}
}