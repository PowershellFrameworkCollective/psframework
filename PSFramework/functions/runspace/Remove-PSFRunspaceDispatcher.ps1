function Remove-PSFRunspaceDispatcher {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	process {
		foreach ($entry in $Name) {
			if (-not $script:runspaceDispatchers[$entry]) { continue }
			$script:runspaceDispatchers[$entry].Stop()
			$script:runspaceDispatchers.Remove($entry)
		}
	}
}