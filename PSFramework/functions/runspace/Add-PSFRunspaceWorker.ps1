function Add-PSFRunspaceWorker {
	<#
	.SYNOPSIS
		Adds a new worker / workload to a runspace workflow.
	
	.DESCRIPTION
		Adds a new worker / workload to a runspace workflow.
		
		The worker as a conceptually consists of three parts:
		- Input Queue: A queue where data to process awaits
		- N Runspaces to convert input to output
		- Output Queue: A queue where the finished results are passed off to.

		In the wider flow of a Runspace Workflow, one Worker's Output Queue is alse another Worker's Input Queue.
		Thus we create a chain of workers from original input to finished output, each step individually with as many runspaces as needed.
	
	.PARAMETER Name
		Name of the worker.
		The name matters little, other than that it must be unique from other workers on the same workflow.
	
	.PARAMETER InQueue
		Name of the queue from which to receive input.
		The name is arbitrary - if the queue does not yet exist on the workflow, it will be auto-created.
	
	.PARAMETER OutQueue
		Name of the queueue to which we write output.
		The name is arbitrary - if the queue does not yet exist on the workflow, it will be auto-created.
	
	.PARAMETER ScriptBlock
		The scriptblock performing the actual workload.
		Receives one argument: The input.
		All output will be - separately - enqueued to the out queue.

		If your scriptblock is one long-running task, rather than many infrequent ones,
		consider using "Write-PSFRunspaceQueue" to pass on output as you generate it and not wait for the scriptblock to run its course.
	
	.PARAMETER Count
		How many parallel runspaces should be created in this worker?
		Defaults to 1
	
	.PARAMETER Begin
		A piece of logic that is executed once at the beginning for each runspace
		So if you set Count to 5, it will run 5 separate times, one per runspace.
	
	.PARAMETER End
		A piece of logic that is executed once at the end for each runspace
		So if you set Count to 5, it will run 5 separate times, one per runspace.
	
	.PARAMETER KillToStop
		When stopping a worker, by default, it will be sent the shutdown signal and will then gracefully terminate.
		This however requires the worker to cycle often enough to catch that signal.
		If this is impossible - for example, if the worker has one long-running piece - and we still need to be able to just kill it, set this flag.
		This means that on stop, all worker runspaces will be killed - without doing any cleanup!
	
	.PARAMETER Throttle
		A throttle object, as returned by New-PSFThrottle.
		This allows rate-limiting the worker runspaces, useful when parallelizing access to an API.
	
	.PARAMETER Variables
		Any variables to provide to the worker runspaces.
		All worker runspaces will have the same variables.
		Beware: Modifications to the objects in those variables are NOT synchronized across runspaces, so keep concurrency in mind if you want to do more than read.
	
	.PARAMETER VarPerRunspace
		Any variables to provide to the worker runspaces.
		To each variable name, match as many values as you plan to have runspaces for this worker.
		So, if you set Count to 3, each variable here should have three values:
		@{ Key = $key1, $key2, $key3 }
		While the order is not guaranteed, each worker runspace will receive its own, unique value for its variable.
		- If you provide more values than Count, only the first Count values will be used
		- If you provide less values than Count, the variable will be $null for any runspace beyond the count of values.
	
	.PARAMETER Modules
		Modules to load into the background runspace.
	
	.PARAMETER Functions
		Functions to load into the background runspace.
		The key is the name of the function, the value its code.
		The code can be either a string or a scriptblock.

		Note: If running in Constrained Language Mode, stricter requirements need to be met:
		- Code must be a scriptblock
		- The scriptblock must be in Full Language Mode

		If you are using this from a module intended for public consumption, please provide a scriptblock as code, not text:
		@{ 'Get-Something' = [ScriptBlock]::Create((Get-Command Get-Something -Module MyModule).Definition) }
	
	.PARAMETER SessionState
		A fully prepared session state object to use when creating the worker runspaces.
		Be aware that if your session state does not contain basic language tools, the background runspace will likely fail.
	
	.PARAMETER WorkflowName
		Name of the Runspace Workflow this worker belongs to.
		The workflow contains all the workers, queues and management tools for the Runspace Workload.
	
	.PARAMETER InputObject
		Workflow object this worker belongs to.
		The workflow contains all the workers, queues and management tools for the Runspace Workload.
	
	.EXAMPLE
		PS C:\> $workflow | Add-PSFRunspaceWorker -Name DoubleIt -InQueue Q1 -OutQueue Q2 -Count 5 -ScriptBlock { $args[0] * 2 }
		
		Adds a worker to the workflow that will take items from Q1, double them, then write them to Q2.
		Will create 5 runspaces to do the job.

	.EXAMPLE
		PS C:\> $workflow | Add-PSFRunspaceWorker -Name Mailboxes -InQueue Organizations -OutQueue Mailboxes -Count 1 -Variables $connectionData -Begin $logonScript -ScriptBlock $getMailbox -End $logoutScript

		Adds a worker that will for each organization retrieve the mailboxes.
		Will create 1 runspace to avoid hitting EXO throttling.
		More detailed examples and explanations can be found on psframework.org.
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html

	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>
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
		$WorkflowName,

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
		$resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $WorkflowName -InputObject $InputObject -Cmdlet $PSCmdlet -Terminate

		foreach ($resolvedWorkflow in $resolvedWorkflows) {
			$worker = $resolvedWorkflow.AddWorker($Name, $InQueue, $OutQueue, $ScriptBlock, $Count)

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