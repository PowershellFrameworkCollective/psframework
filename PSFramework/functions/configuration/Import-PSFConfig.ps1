function Import-PSFConfig
{
<#
	.SYNOPSIS
		Imports a json configuration file into the configuration system.
	
	.DESCRIPTION
		Imports a json configuration file into the configuration system.
	
	.PARAMETER Path
		The path to the json file to import.
	
	.PARAMETER ModuleName
		Import configuration items specific to a module from the default configuration paths.
	
	.PARAMETER ModuleVersion
		The configuration version of the module-settings to load.
	
	.PARAMETER Scope
		Where to import the module specific configuration items form.
		Only file-based scopes are supported for this.
		By default, all locations are queried, with user settings beating system settings.
	
	.PARAMETER Schema
		The configuration schema to use for import.
		Use Register-PSFConfigSchema to extend the way input content can be laid out.
	
	.PARAMETER IncludeFilter
		If specified, only elements with names that are similar (-like) to names in this list will be imported.
	
	.PARAMETER ExcludeFilter
		Elements that are similar (-like) to names in this list will not be imported.
	
	.PARAMETER Peek
		Rather than applying the setting, return the configuration items that would have been applied.
	
	.PARAMETER AllowDelete
		Configurations that have been imported will be flagged as deletable.
		This allows to purge them at a later time using Remove-PSFConfig.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Import-PSFConfig -Path '.\config.json'
		
		Imports the configuration stored in '.\config.json'
	
	.EXAMPLE
		PS C:\> Import-PSFConfig -ModuleName mymodule
	
		Imports all the module specific settings that have been persisted in any of the default file system paths.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding(DefaultParameterSetName = "Path", HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Import-PSFConfig')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Path")]
		[string[]]
		$Path,
		
		[Parameter(ParameterSetName = "ModuleName", Mandatory = $true)]
		[string]
		$ModuleName,
		
		[Parameter(ParameterSetName = "ModuleName")]
		[int]
		$ModuleVersion = 1,
		
		[Parameter(ParameterSetName = "ModuleName")]
		[PSFramework.Configuration.ConfigScope]
		$Scope = "FileUserLocal, FileUserShared, FileSystem",
		
		[Parameter(ParameterSetName = "Path")]
		[PsfValidateSet(TabCompletion = 'PSFramework-Config-Schema')]
		[string]
		$Schema = "Default",
		
		[Parameter(ParameterSetName = "Path")]
		[string[]]
		$IncludeFilter,
		
		[Parameter(ParameterSetName = "Path")]
		[string[]]
		$ExcludeFilter,
		
		[Parameter(ParameterSetName = "Path")]
		[switch]
		$Peek,
		
		[Parameter(ParameterSetName = 'Path')]
		[switch]
		$AllowDelete,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
		
		$settings = @{
			IncludeFilter = $IncludeFilter
			ExcludeFilter = $ExcludeFilter
			Peek		  = $Peek.ToBool()
			AllowDelete   = $AllowDelete.ToBool()
			EnableException = $EnableException.ToBool()
			Cmdlet	      = $PSCmdlet
			Path = (Get-Location).Path
		}
		
		$schemaScript = [PSFramework.Configuration.ConfigurationHost]::Schemata[$Schema]
	}
	process
	{
		#region Explicit Path
		foreach ($item in $Path)
		{
			try { $resolvedItem = Resolve-PSFPath -Path $item -Provider FileSystem }
			catch { $resolvedItem = $item }
			
			foreach ($rItem in $resolvedItem)
			{
				& $schemaScript $rItem $settings
			}
		}
		#endregion Explicit Path
		
		#region ModuleName
		if ($ModuleName)
		{
			$data = Read-PsfConfigPersisted -Module $ModuleName -Scope $Scope -ModuleVersion $ModuleVersion
			
			foreach ($value in $data.Values)
			{
				if (-not $value.KeepPersisted) { Set-PSFConfig -FullName $value.FullName -Value $value.Value -EnableException:$EnableException}
				else { Set-PSFConfig -FullName $value.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($value.Value, $value.Type)) -EnableException:$EnableException }
			}
		}
		#endregion ModuleName
	}
}