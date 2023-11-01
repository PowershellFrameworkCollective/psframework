function Get-PSFRunspaceWorker {
	[CmdletBinding()]
	param (
		[string]
		$Name = '*',

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$DispatcherName,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject
	)
	process {
		$resolvedDispatchers = Resolve-PsfRunspaceDispatcher -Name $DispatcherName -InputObject $InputObject -Cmdlet $PSCmdlet

		$resolvedDispatchers.Workers.Values | Where-Object Name -Like $Name
	}
}