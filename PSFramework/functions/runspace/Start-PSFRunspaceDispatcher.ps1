function Start-PSFRunspaceDispatcher {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name,

		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSDispatcher[]]
		$InputObject
	)
	process {
		$resolvedDispatchers = Resolve-PsfRunspaceDispatcher -Name $Name -InputObject $InputObject -Cmdlet $PSCmdlet

		foreach ($resolvedDispatcher in $resolvedDispatchers) {
			$resolvedDispatcher.Start()
		}
	}
}