function Invoke-PSFRunspace {
	<#
	.SYNOPSIS
		Execute a scriptblock in parallel.
	
	.DESCRIPTION
		Execute a scriptblock in parallel.

		This command offers two separate "modes" of operation:
		- Similar to "ForEach-Object -Parallel" within a PowerShell pipeline.
		- Similar to "Start-ThreadJob", in that it returns a task object you can collect reults from later.

		In the former scenario, it offers redirecting all the streams (verbose, warning, errors, ...) for each task into the main runspace.
		Supports importing variables into the background runspaces using the "$using:"-statement
	
	.PARAMETER ScriptBlock
		The code to execute in parallel.
	
	.PARAMETER InputObject
		The items for which to execute the scriptblock.
		One instance per item, whether piped or provided explicitly.
	
	.PARAMETER AsTask
		Rather than wait for the processing to complete, return an object representing the overall execution.
		To collect the results, call one of the following methods on the object:
		- Collect(): Wait until everything is completed and collect the output.
		- CollectCurrent(): Collect the output of tasks that have completed so far
		- CollectResult(): Wait until everything is completed and collect report objects for each item, including the different streams, input and output
		- CollectCurrentResult(): Collect report objects for each task already completed, including the different streams, input and output

	.PARAMETER Name
		Name of the runspace workload.
		Documentary only.
		Defaults to: <undefined>
	
	.PARAMETER OutputStyle
		How should output be processed.
		- Output: Produce the output of each task as output of this command. Redirect all background-streams into this command's streams unless combined ith "-NoStreams"
		- Result: Each task is completed with a results object, including the different streams, input and output
		Has no effect when used with "-AsTask"
		Defaults to: Output
	
	.PARAMETER ThrottleLimit
		How man tasks are executed in parallel.
		Defaults to: 5
	
	.PARAMETER Variables
		Any variables to provide to the background runspaces.
		Maps name to value.
		You can also import variables into the background runspaces by using the "$using:"-statement
	
	.PARAMETER Functions
		Any functions to import into the background runspace.
		Maps name to code.
		Code can be either text or scriptblock:
		- @{ 'Get-Example' = (Get-Command Get-Example).Definition }
		- @{ 'Get-Example' = [scriptblock]::Create((Get-Command Get-Example).Definition) }
		
		Note:
		In a secured environment, where PowerShell Constrained Language Mode has been deployed, only the scriptblock-variant will work!
	
	.PARAMETER Modules
		Any modules to include in the background runspaces.
	
	.PARAMETER ImportPSFramework
		Import the PSFramework into the background runspaces.
	
	.PARAMETER NoStreams
		Do not redirect background streams into the streams of Invoke-PSFRunspace.
		Has no effect when using either "-AsTask" or "-OutputStyle Result".
	
	.PARAMETER InitialSessionState
		A full initial session state object you preconfigured to operate the background tasks.
		Note: Variables, type references & method invocations must work for this command to succeed.
	
	.EXAMPLE
		PS C:\> Get-ADUser -Filter * | Invoke-PSFRunspace { $_ | Get-ADPrincipalGroupMembership }

		Retrieve all users from Active Directory, then retrieve their group memberships

	.EXAMPLE
		PS C:\> Get-ADUser -Filter * | Invoke-PSFRunspace { $_ | Get-ADPrincipalGroupMembership } -OutputStyle Result

		Retrieve all users from Active Directory, then retrieve their group memberships, returning a report object, mapping each user to their group memberships.

	.EXAMPLE
		PS C:\> $task = Get-ADUser -Filter * | Invoke-PSFRunspace { $_ | Get-ADPrincipalGroupMembership }
		PS C:\> $task.CollectResult()

		First start searching for all users' group memberships.
		Then later collect all the results in convenient result datasets, mapping input to output and including all errors / warnings / etc.
	#>
	[OutputType([PSFramework.Runspace.RunspaceWrapper])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ScriptBlock]
		$ScriptBlock,

		[Parameter(ValueFromPipeline = $true)]
		$InputObject,

		[switch]
		$AsTask,

		[string]
		$Name = '<undefined>',

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
		$runspaceWrapper.ThrottleLimit = $ThrottleLimit
		$runspaceWrapper.Name = $Name
		
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

		#region Handle Code
		$actualCode = $ScriptBlock

		if ($actualCode.Ast.Extent.Text -match '\$using:') {
			$convertedCodeData = ConvertFrom-PsfUsingStatement -ScriptBlock $actualCode
			$actualCode = $convertedCodeData.Code
			foreach ($variableName in $convertedCodeData.Variables) {
				$runspaceWrapper.AddVariable($variableName, $PSCmdlet.SessionState.PSVariable.Get($variableName).Value)
			}
		}

		$runspaceWrapper.Code = $actualCode
		#endregion Handle Code
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