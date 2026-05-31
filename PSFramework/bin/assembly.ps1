try {
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Add-Type -Path "$script:ModuleRoot\bin\PSFramework.dll" -ErrorAction Stop
    }
    else {
        Add-Type -Path "$script:ModuleRoot\bin\PS4\PSFramework.dll" -ErrorAction Stop
    }
}
catch {
    Write-Warning "Failed to load PSFramework Assembly! Unable to import module."
    throw
}
try {
	$lock = [PSFramework.Runspace.RunspaceHost]::GetRunspaceLock('PSFramework.Types')
	$lock.Open()
    Update-TypeData -AppendPath "$script:ModuleRoot\xml\PSFramework.Types.ps1xml" -ErrorAction Stop
	$lock.Close()
}
catch {
    Write-Warning "Failed to load PSFramework type extensions! Unable to import module."
    throw
}