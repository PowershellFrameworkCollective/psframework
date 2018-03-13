#region Handle Module Removal
$PSF_OnRemoveScript = {
	Get-PSFRunspace | Stop-PSFRunspace
}
$ExecutionContext.SessionState.Module.OnRemove += $PSF_OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $PSF_OnRemoveScript
#endregion Handle Module Removal