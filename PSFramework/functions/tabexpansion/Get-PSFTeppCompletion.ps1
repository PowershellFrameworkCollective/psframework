function Get-PSFTeppCompletion {
	<#
	.SYNOPSIS
		Lists the registered completion options.
		
	.DESCRIPTION
		Lists the registered completion options.
		Using Add-PSFTeppCompletion, it is possible to manually provide values that will be offered during tab completion for a given argument completion script.
		Alternatively, a completion scriptblock can be configured for "AutoTraining" during setup via "Register-PSFTeppScriptblock", which enables automatically
		remembering values previously provided (By later calling Update-PSFTeppCompletion).

		In either case, those values are stored in memory and retrieved using this command.
	
	.PARAMETER Name
		Name of the completer scriptblock, for which to retrieve registered options.
		Defaults to *
	
	.EXAMPLE
		PS C:\> Get-PSFTeppCompletion

		List all registered completion options for all completer scriptblocks.
	#>
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('PSFramework-tepp-scriptblockname')]
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Name = '*'
	)
	begin {
		$completerScripts = [PSFramework.TabExpansion.TabExpansionHost]::Scripts.Values
		$processed = @{ }
	}
	process {
		foreach ($entry in $Name) {
			foreach ($completerScript in $completerScripts) {
				if ($processed[$completerScript]) { continue }
				if ($completerScript.Name -notlike $entry) { continue }

				$processed[$completerScript] = $completerScript

				foreach ($completionResult in $completerScript.Trained) {
					if (-not $completionResult) { continue }
					$newResult = $completionResult.Clone()
					$newResult.PSTypeName = 'PSFramework.TabExpansion.CompletionData'
					$newResult.Completion = $completerScript.Name
					[PSCustomObject]$newResult
				}
			}
		}
	}
}