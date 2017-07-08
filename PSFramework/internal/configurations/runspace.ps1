#region Setting the configuration
Set-PSFConfig -Module PSFramework -Name 'Runspace.StopTimeoutSeconds' -Value 30 -Initialize -Validation "integerpositive" -Handler { [PSFramework.Runspace.RunspaceHost]::StopTimeoutSeconds = $args[0] } -Description "Time in seconds that Stop-PSFRunspace will wait for a scriptspace to selfterminate before killing it."
#endregion Setting the configuration