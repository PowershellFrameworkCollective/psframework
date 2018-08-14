#region Handle Module Removal
$PSF_OnRemoveScript = {
	# Stop all managed runspaces ONLY on the main runspace's termination
	if ([runspace]::DefaultRunspace.Id -eq 1)
	{
		Get-PSFRunspace | Stop-PSFRunspace
	}
	
	# Properly disconnect all remote sessions still held open
	$psframework_pssessions.Values | Remove-PSSession
}
$ExecutionContext.SessionState.Module.OnRemove += $PSF_OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $PSF_OnRemoveScript
#endregion Handle Module Removal