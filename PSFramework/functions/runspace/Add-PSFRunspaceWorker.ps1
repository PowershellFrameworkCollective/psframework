function Add-PSFRunspaceWorker {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[string]
		$InQueue,

		[Parameter(Mandatory = $true)]
		[string]
		$OutQueue,

		[Parameter(Mandatory = $true)]
		[ScriptBlock]
		$ScriptBlock,

		[int]
		$Count = 1,

		[ScriptBlock]
		$Begin,

		[ScriptBlock]
		$End,

		[switch]
		$KillToStop,

		[PSFramework.Utility.Throttle]
		$Throttle,

		[hashtable]
		$Variables,

		[hashtable]
		$VarPerRunspace,

		[string[]]
		$Modules,

		[hashtable]
		$Functions,

		[initialsessionstate]
		$SessionState,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$DispatcherName,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject
	)

	begin {
		$functionsResolved = @{ }

		if (-not $Functions) { return }

		$consoleConstrained = [PSFramework.PSFCore.PSFCoreHost]::ConstrainedConsole

		foreach ($pair in $Functions.GetEnumerator()) {
			if ($consoleConstrained -and $pair.Value -isnot [ScriptBlock]) {
				Stop-PSFFunction -String 'Add-PSFRunspaceWorker.Error.UntrustedTextFunction' -StringValues $pair.Key -EnableException $true -Cmdlet $PSCmdlet -Category SecurityError
			}
			if ($consoleConstrained -and ([PsfScriptBlock]$pair.Value).LanguageMode -ne 'FullLanguage') {
				Stop-PSFFunction -String 'Add-PSFRunspaceWorker.Error.UntrustedFunctionCode' -StringValues $pair.Key -EnableException $true -Cmdlet $PSCmdlet -Category SecurityError
			}
			if ($pair.Value -is [ScriptBlock]) {
				$functionsResolved[$pair.Key] = $pair.Value
				continue
			}
			$functionsResolved[$pair.Key] = [scriptblock]::Create($pair.Value)
		}
	}
	process {
		$resolvedDispatchers = Resolve-PsfRunspaceDispatcher -Name $DispatcherName -InputObject $InputObject -Cmdlet $PSCmdlet -Terminate

		foreach ($resolvedDispatcher in $resolvedDispatchers) {
			$worker = $resolvedDispatcher.AddWorker($Name, $InQueue, $OutQueue, $ScriptBlock, $Count)

			if ($Begin) { $worker.Begin = $Begin }
			if ($End) { $worker.End = $End }

			if ($SessionState) { $worker.SessionState = $SessionState }
			foreach ($module in $Modules) { $worker.Modules.Add($module) }
			foreach ($varName in $Variables.Keys) { $worker.Variables[$varName] = $Variables[$varName] }
			foreach ($functionName in $functionsResolved.Keys) { $worker.Functions[$functionName] = $functionsResolved[$functionName] }
			if ($VarPerRunspace) {
				foreach ($pair in $VarPerRunspace.GetEnumerator()) {
					$worker.PerRSValues[$pair.Key] = [PSFramework.Runspace.RSQueue]::new()
					foreach ($value in $pair.Value) {
						$worker.PerRSValues[$pair.Key].Enqueue($value)
					}
				}
			}
			if ($KillToStop) { $worker.KillToStop = $true }
			if ($Throttle) { $worker.THrottle = $Throttle }

			$worker
		}
	}
}