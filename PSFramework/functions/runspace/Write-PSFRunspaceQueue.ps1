function Write-PSFRunspaceQueue {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[AllowNull()]
		$Value,

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
			$resolvedDispatcher.Queues.$Name.Enqueue($Value)
			if ($global:__PSF_Worker -and $Name -eq $global:__PSF_Worker.OutQueue) {
				$global:__PSF_Worker.IncrementOutput()
			}
		}
	}
}