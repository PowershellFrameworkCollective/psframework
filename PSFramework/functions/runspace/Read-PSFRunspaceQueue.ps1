function Read-PSFRunspaceQueue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[switch]
		$All,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$DispatcherName,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject
	)
	process {
		$resolvedDispatchers = Resolve-PsfRunspaceDispatcher -Name $DispatcherName -InputObject $InputObject -Cmdlet $PSCmdlet -Terminate -CurrentWorker
		foreach ($resolvedDispatcher in $resolvedDispatchers) {
			if ($All) {
				$resolvedDispatcher.Queues.$Name.ToArray()
				$resolvedDispatcher.Queues.$Name.Clear()
				continue
			}
			$result = $resolvedDispatcher.Queues.$Name.DeQueue()
			if ($null -ne $result) { $result }
		}
	}
}