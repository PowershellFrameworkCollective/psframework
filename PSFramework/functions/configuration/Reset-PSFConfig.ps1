function Reset-PSFConfig
{
<#
	.SYNOPSIS
		Reverts a configuration item to its default value.
	
	.DESCRIPTION
		This command can be used to revert a configuration item to the value it was initialized with.
		Generally, this amounts to reverting it to its default value.
		
		In order for a reset to be possible, two conditions must be met:
		- The setting must have been initialized.
		- The setting cannot have been enforced by policy.
	
	.PARAMETER ConfigurationItem
		A configuration object as returned by Get-PSFConfig.
	
	.PARAMETER FullName
		The full name of the setting to reset, offering the maximum of precision.
	
	.PARAMETER Module
		The name of the module, from which configurations should be reset.
		Used in conjunction with the -Name parameter to filter a specific set of items.
	
	.PARAMETER Name
		Used in conjunction with the -Module parameter to select which settings to reset using wildcard comparison.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> Reset-PSFConfig -Module MyModule
	
		Resets all configuration items of the MyModule to default.
	
	.EXAMPLE
		PS C:\> Get-PSFConfig | Reset-PSFConfig
	
		Resets ALL configuration items to default.
	
	.EXAMPLE
		PS C:\> Reset-PSFConfig -FullName MyModule.Group.Setting1
	
		Resets the configuration item named 'MyModule.Group.Setting1'.
#>
	[CmdletBinding(DefaultParameterSetName = 'Pipeline', SupportsShouldProcess = $true, ConfirmImpact = 'Low', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Reset-PSFConfig')]
	param (
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[PSFramework.Configuration.Config[]]
		$ConfigurationItem,
		
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Pipeline')]
		[string[]]
		$FullName,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Module')]
		[string]
		$Module,
		
		[Parameter(ParameterSetName = 'Module')]
		[string]
		$Name = "*",
		
		[switch]
		$EnableException
	)
	
	process
	{
		#region By configuration Item
		foreach ($item in $ConfigurationItem)
		{
			if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $item.FullName -ActionString 'Reset-PSFConfig.Resetting')
			{
				try { $item.ResetValue() }
				catch { Stop-PSFFunction -String 'Reset-PSFConfig.Resetting.Failed' -ErrorRecord $_ -Cmdlet $PSCmdlet -Continue -EnableException $EnableException }
			}
		}
		#endregion By configuration Item
		
		#region By FullName
		foreach ($nameItem in $FullName)
		{
			# The configuration items themselves can be cast to string, so they need to be filtered out,
			# otherwise on bind they would execute for this code-path as well.
			if ($nameItem -ceq "PSFramework.Configuration.Config") { continue }
			
			foreach ($item in (Get-PSFConfig -FullName $nameItem))
			{
				if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $item.FullName -ActionString 'Reset-PSFConfig.Resetting')
				{
					try { $item.ResetValue() }
					catch { Stop-PSFFunction -String 'Reset-PSFConfig.Resetting.Failed' -ErrorRecord $_ -Cmdlet $PSCmdlet -Continue -EnableException $EnableException}
				}
			}
		}
		#endregion By FullName
		if ($Module)
		{
			foreach ($item in (Get-PSFConfig -Module $Module -Name $Name))
			{
				if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $item.FullName -ActionString 'Reset-PSFConfig.Resetting')
				{
					try { $item.ResetValue() }
					catch { Stop-PSFFunction -String 'Reset-PSFConfig.Resetting.Failed' -ErrorRecord $_ -Cmdlet $PSCmdlet -EnableException $EnableException -Continue }
				}
			}
		}
	}
}