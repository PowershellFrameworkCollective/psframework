function Invoke-PSFRunspace {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ScriptBlock]
		$ScriptBlock,

		[Parameter(ValueFromPipeline = $true)]
		$InputObject,

		[switch]
		$AsTask,

		[ValidateSet('Output', 'Result')]
		[string]
		$OutputStyle = 'Output',

		[int]
		$ThrottleLimit = 5,

		[ValidateNotNull()]
		[hashtable]
		$Variables = @{},

		[ValidateNotNull()]
		[hashtable]
		$Functions = @{},

		[object[]]
		$Modules,

		[switch]
		$ImportPSFramework,

		[switch]
		$NoStreams,

		[initialsessionstate]
		$InitialSessionState
	)
	begin {
		$runspaceWrapper = [PSFramework.Runspace.RunspaceWrapper]::new()

		#region Provide Context
		if ($InitialSessionState) { $runspaceWrapper.initialsessionstate = $InitialSessionState }
		
		$runspaceWrapper.AddVariable($Variables)

		# See usually invisible background streams
		$runspaceWrapper.AddVariable("VerbosePreference", $VerbosePreference)
		$runspaceWrapper.AddVariable("InformationPreference", $InformationPreference)

		if ($ImportPSFramework) { $runspaceWrapper.AddModule((Get-Module PSFramework)) }
		foreach ($module in $Modules) {
			try { $runspaceWrapper.AddModule($module) }
			catch { Stop-PSFFunction -String 'Invoke-PSFRunspace.Error.ModuleImport' -StringValues $module -EnableException $true -Cmdlet $PSCmdlet }
		}

		foreach ($pair in $Functions.GetEnumerator()) {
			if ($consoleConstrained -and $pair.Value -isnot [ScriptBlock]) {
				Stop-PSFFunction -String 'Invoke-PSFRunspace.Error.UntrustedTextFunction' -StringValues $pair.Key -EnableException $true -Cmdlet $PSCmdlet -Category SecurityError
			}
			if ($consoleConstrained -and ([PsfScriptBlock]$pair.Value).LanguageMode -ne 'FullLanguage') {
				Stop-PSFFunction -String 'Invoke-PSFRunspace.Error.UntrustedFunctionCode' -StringValues $pair.Key -EnableException $true -Cmdlet $PSCmdlet -Category SecurityError
			}
			if ($pair.Value -is [ScriptBlock]) {
				$runspaceWrapper.AddFunction($pair.Key, $pair.Value)
				$functionsResolved[$pair.Key] = $pair.Value
				continue
			}
			$runspaceWrapper.AddFunction($pair.Key, [scriptblock]::Create($pair.Value))
		}
		#endregion Provide Context

		$runspaceWrapper.Code = $ScriptBlock
		$runspaceWrapper.ThrottleLimit = $ThrottleLimit
		$runspaceWrapper.Start()
	}
	process {
		if ($PSBoundParameters.Keys -contains 'InputObject') {
			$runspaceWrapper.AddTaskBulk(@($InputObject))
		}
		if ($AsTask) { return }

		switch ($OutputStyle) {
			'Result' { $runspaceWrapper.CollectCurrentResult() }
			default { $runspaceWrapper.CollectCurrent($PSCmdlet, $NoStreams.ToBool()) }
		}
	}
	end {
		if ($AsTask) { return $runspaceWrapper }

		switch ($OutputStyle) {
			'Result' { $runspaceWrapper.CollectResult() }
			default { $runspaceWrapper.Collect($PSCmdlet, $NoStreams.ToBool()) }
		}
		$runspaceWrapper.Stop()
	}
}