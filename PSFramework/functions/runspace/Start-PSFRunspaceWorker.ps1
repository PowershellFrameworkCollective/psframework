function Start-PSFRunspaceWorker {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Runspace.RSWorker[]]
		$InputObject
	)
	process {
		foreach ($item in $InputObject) {
			$item.Start()
		}
	}
}