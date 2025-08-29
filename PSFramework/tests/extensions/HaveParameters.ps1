function HaveParameters {
	[CmdletBinding()]
	param (
		$ActualValue,

		[string[]]
		$Parameters,

		[switch]
		$Negate,

		$CallerSessionState
	)
	end {
		$commonParameters = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'ProgressAction'
		if ($global:__pester_data.CommonParameters) { $commonParameters = $global:__pester_data.CommonParameters }

		#region Resolve Command
		if ($null -eq $ActualValue) {
			return [PSCustomObject]@{
				Succeeded      = $false
				FailureMessage = "Did not receive a command to test"
			}
		}

		$command = $ActualValue
		if ($command -isnot [System.Management.Automation.CommandInfo]) {
			try { $command = Get-Command $ActualValue -ErrorAction Stop }
			catch {
				return [PSCustomObject]@{
					Succeeded      = $false
					FailureMessage = "Unable to resolve command: $ActualValue"
				}
			}
		}
		#endregion Resolve Command

		#region Negation
		if ($Negate) {
			$found = @()
			foreach ($parameter in $Parameters) {
				if ($parameter -notin $command.Parameters.Keys) { continue }
				$found += $parameter
			}

			if ($found) {
				return [PSCustomObject]@{
					Succeeded      = $false
					FailureMessage = "Parameters found on $($command.Name): $($found -join ', ')"
				}
			}
			return [PSCustomObject]@{
				Succeeded      = $true
				FailureMessage = "None of the forbidden parameters found on $($command.Name) (Forbidden: $($Parameters -join ', '))"
			}
		}
		#endregion Negation

		#region Regular Parameter Test
		$notFound = @()
		$excessFound = @()

		foreach ($parameter in $command.Parameters.Keys) {
			if ($parameter -in $commonParameters) { continue }
			if ($parameter -in $Parameters) { continue }
			$excessFound += $parameter
		}

		foreach ($parameter in $Parameters) {
			if ($parameter -in $command.Parameters.Keys) { continue }
			$notFound += $parameter
		}

		if (-not $notFound -and -not $excessFound) {
			return [PSCustomObject]@{
				Succeeded      = $true
				FailureMessage = "All expected parameters found on $($command.Name) (Expected: $($Parameters -join ', '))"
			}
		}

		$fragments = @()
		if ($notFound) { $fragments += "Missing: $($notFound -join ', ')" }
		if ($excessFound) { $fragments += "Unexpected: $($excessFound -join ', ')" }

		return [PSCustomObject]@{
			Succeeded      = $false
			FailureMessage = "Parameters found on $($command.Name) not as desired | Expected: $($Parameters -join ', ') | $($fragments -join ' | ')"
		}
		#endregion Regular Parameter Test
	}
}
Add-ShouldOperator -Name HaveParameters -Test $function:HaveParameters