function Remove-PSFConfig
{
<#
	.SYNOPSIS
		Removes configuration items from memory.
	
	.DESCRIPTION
		This command removes configuration items from memory.
		However, not all settings can just be deleted!
		A configuration item must be flagged as deletable.
		This can be done using Set-PSFConfig -AllowDelete or Import-PSFConfig -AllowDelete.
		Certain schema versions of configuration json may also support defining this in the file.
	
		Limitations to flagging configuration as deletable:
		> Once a configuration item has been initialized, its deletable status is frozen.
		  The last time it is possible to change the deletable status is during initialization.
		> A setting that has been set as mandated by policy cannot be removed.
	
		Reason for this limit:
		The configuration system is designed for multiple scenarios.
		Deleting settings makes sense in some, while in others it is actually detrimental.
		Initialization is especially designed for the module scenario, where the module's configuration is its options menu.
		In this scenario, having a user deleting settings could lead to broken execution and unintended code paths, that might be at odds with policies defined.
	
	.PARAMETER Config
		The configuration object to remove from memory.
		Can be retrieved using Get-PSFConfig.
	
	.PARAMETER FullName
		The full name of the setting to be removed from memory.
	
	.PARAMETER Module
		The name of the module, whose settings should be removed from memory.
	
	.PARAMETER Name
		Default: "*"
		Used in conjunction with the -Module parameter to restrict the number of configuration items deleted from memory.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Remove-PSFConfig -FullName 'Phase1.Step1.Server' -Confirm:$false
	
		Deletes the setting 'Phase1.Step1.Server' from memory, assuming it exists and supports deletion.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipeline = $true)]
		[PSFramework.Configuration.Config[]]
		$Config,
		
		[Parameter(ParameterSetName = "Default", Position = 0, ValueFromPipeline = $true)]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Name", Position = 0)]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = "Name", Position = 1)]
		[string]
		$Name = "*"
	)
	
	process
	{
		switch ($PSCmdlet.ParameterSetName)
		{
			"Default"
			{
				#region Try removing all items specified
				foreach ($item in $Config)
				{
					if (-not (Test-PSFShouldProcess -ActionString 'Configuration.Remove-PSFConfig.ShouldRemove' -Target $item.FullName)) { continue }
					try { $result = [PSFramework.Configuration.ConfigurationHost]::DeleteConfiguration($item.FullName) }
					catch { Stop-PSFFunction -String Configuration.Remove-PSFConfig.InvalidConfiguration -StringValues $item.FullName -EnableException ($ErrorActionPreference -eq 'Stop') -Continue -Cmdlet $PSCmdlet -ErrorRecord $_ }
					
					if ($result) { Write-PSFMessage -Level InternalComment -String Configuration.Remove-PSFConfig.DeleteSuccessful -StringValues $item.FullName }
					else { Write-PSFMessage -Level Warning -String Configuration.Remove-PSFConfig.DeleteFailed -StringValues $item.FullName, $item.AllowDelete, $item.PolicyEnforced }
				}
				# Since configuration items will also bind to string, if any were included, break the switch
				if (Test-PSFParameterBinding -ParameterName Config) { break }
				#endregion Try removing all items specified
				
				#region Try removing all full names specified
				foreach ($nameItem in $FullName)
				{
					if (-not (Test-PSFShouldProcess -ActionString 'Configuration.Remove-PSFConfig.ShouldRemove' -Target $nameItem)) { continue }
					$item = Get-PSFConfig -FullName $nameItem
					
					try { $result = [PSFramework.Configuration.ConfigurationHost]::DeleteConfiguration($nameItem) }
					catch { Stop-PSFFunction -String Configuration.Remove-PSFConfig.InvalidConfiguration -StringValues $nameItem -EnableException ($ErrorActionPreference -eq 'Stop') -Continue -Cmdlet $PSCmdlet -ErrorRecord $_ }
					
					
					if ($result) { Write-PSFMessage -Level InternalComment -String Configuration.Remove-PSFConfig.DeleteSuccessful -StringValues $item.FullName }
					else { Write-PSFMessage -Level Warning -String Configuration.Remove-PSFConfig.DeleteFailed -StringValues $item.FullName, $item.AllowDelete, $item.PolicyEnforced }
				}
				#endregion Try removing all full names specified
			}
			"Name"
			{
				#region Try removing by filter
				foreach ($item in (Get-PSFConfig -Module $Module -Name $Name))
				{
					if (-not (Test-PSFShouldProcess -ActionString 'Configuration.Remove-PSFConfig.ShouldRemove' -Target $item.FullName)) { continue }
					
					try { $result = [PSFramework.Configuration.ConfigurationHost]::DeleteConfiguration($item.FullName) }
					catch { Stop-PSFFunction -String Configuration.Remove-PSFConfig.InvalidConfiguration -StringValues $item.FullName -EnableException ($ErrorActionPreference -eq 'Stop') -Continue -Cmdlet $PSCmdlet -ErrorRecord $_ }
					
					if ($result) { Write-PSFMessage -Level InternalComment -String Configuration.Remove-PSFConfig.DeleteSuccessful -StringValues $item.FullName }
					else { Write-PSFMessage -Level Warning -String Configuration.Remove-PSFConfig.DeleteFailed -StringValues $item.FullName, $item.AllowDelete, $item.PolicyEnforced }
				}
				#endregion Try removing by filter
			}
		}
	}
}