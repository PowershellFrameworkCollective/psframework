#region Handle Module Removal
$PSF_OnRemoveScript = {
	# Stop all managed runspaces ONLY on the main runspace's termination
	if ([runspace]::DefaultRunspace.Id -eq 1)
	{
		Wait-PSFMessage -Timeout 30s -Terminate
		Get-PSFRunspace | Stop-PSFRunspace
		[PSFramework.PSFCore.PSFCoreHost]::Uninitialize()
	}
	
	# Properly disconnect all remote sessions still held open
	$psframework_pssessions.Values | Remove-PSSession
	# Remove all Runspace-specific callbacks
	[PSFramework.FlowControl.CallbackHost]::RemoveRunspaceOwned()
}
$ExecutionContext.SessionState.Module.OnRemove += $PSF_OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $PSF_OnRemoveScript
#endregion Handle Module Removal