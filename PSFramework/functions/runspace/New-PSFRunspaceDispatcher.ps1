function New-PSFRunspaceDispatcher {
	[OutputType([PSFramework.Runspace.RSDispatcher])]
	[CmdletBinding()]
	param (
		[string]
		$Name,

		[switch]
		$Force
	)
	process {
		if ($script:runspaceDispatchers[$Name]) {
			if (-not $Force) {
				Stop-PSFFunction -String 'New-PSFRunspaceDispatcher.Error.ExistsAlready' -StringValues $Name -EnableException $true -Cmdlet $PSCmdlet
			}

			$script:runspaceDispatchers[$Name].Stop()
		}

		$script:runspaceDispatchers[$Name] = [PSFramework.Runspace.RSDispatcher]::new($Name)
		$script:runspaceDispatchers[$Name]
	}
}