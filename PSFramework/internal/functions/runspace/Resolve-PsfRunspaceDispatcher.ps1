function Resolve-PsfRunspaceDispatcher {
	[OutputType([PSFramework.Runspace.RSDispatcher])]
	[CmdletBinding()]
	param (
		[string[]]
		$Name,

		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject,

		$Cmdlet,

		[switch]
		$Terminate,

		[switch]
		$CurrentWorker
	)
	process {
		if (-not ($Name -or $InputObject)) {
			if ($CurrentWorker -and $global:__PSF_Dispatcher) {
				return $global:__PSF_Dispatcher
			}

			if ($Terminate) {
				Stop-PSFFunction -String 'Resolve-PsfRunspaceDispatcher.Error.NoInput' -EnableException $true -Cmdlet $Cmdlet -Category ObjectNotFound
			}
			$exception = [System.ArgumentException]::new("Must provide either name or an input object!")
			Write-PSFMessage -Level Error -String 'Stop-PSFRunspaceDispatcher.Error.NoInput' -Exception $exception -EnableException $true -PSCmdlet $Cmdlet
			return
		}

		$list = @()
		foreach ($item in $InputObject) {
			if ($item -in $list) { continue }
			$list += $item
		}

		foreach ($entry in $Name) {
			$dispatchers = Get-PSFRunspaceDispatcher -Name $entry
			foreach ($item in $dispatchers) {
				if ($item -in $list) { continue }
				$list += $item
			}
		}

		if (-not $list) {
			if ($Terminate) {
				Stop-PSFFunction -String 'Resolve-PsfRunspaceDispatcher.Error.NotFound' -StringValues ($Name -join ', ') -EnableException $true -Cmdlet $Cmdlet -Category ObjectNotFound
			}
			$exception = [System.ArgumentException]::new("Cannot resolve Runspace Dispatcher: $($Name -join ', ')")
			Write-PSFMessage -Level Error -String 'Stop-PSFRunspaceDispatcher.Error.NotFound' -Exception $exception -EnableException $true -PSCmdlet $Cmdlet
			return
		}

		$list
	}
}