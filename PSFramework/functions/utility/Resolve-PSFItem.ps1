function Resolve-PSFItem {
	<#
	.SYNOPSIS
		Resolves paths provided.
	
	.DESCRIPTION
		Resolves paths provided.
		This command is designed as the ultimate tool for resolving paths provided with all flow control decisions handled.

		The key difference between this command and Resolve-PSFPath is that this command directly integrates into the caller for the purposes of error handling.
		It also handles a lot of the flow control issues merging and refining input and informing about issues.

		Resolve-PSFPath simply takes a path and resolves that one path.
	
	.PARAMETER Path
		The paths to resolve.
		Interprets wildcards.
	
	.PARAMETER LiteralPath
		The paths to resolve.
		Does not interpret wildcards.
	
	.PARAMETER Type
		What kind of item to return:
		- Any: Return anything of the correct provider.
		- File/Leaf: Only return file (or leaf) objects.
		- Directory/Container: Only return directory (or container) objects.
		Default: Any
	
	.PARAMETER ResolutionMode
		The resolution mode determines in which situation the command figures there is an actual error.
		ErrorMode then determines how bad of an error to generate.
		- Any: Any number of results (including none) is ok. In this scenario we do not generate an error.
		- All: For each path provided, at least one item must be found. Any input path without result causes an error.
		- AtLeastOne: At least one path must have been found in total
		- OnlyOne: More than one result in total causes an error.
		Default: Any
	
	.PARAMETER WarningMode
		Warnings are potentially generated for each path that has no result.
		Warning processing is independent of error handling.
		- None: No warning is generated, no matter what
		- One: One summary warning is generated, listing all input paths without a result
		- All: One warning is generated for each path without results
		Default: One
	
	.PARAMETER ErrorMode
		If the ResolutionMode has determined, that an error state exists, it is up to this ErrorMode parameter to determine just what kind of error state happens.
		- Terminating: A terminating error is generated
		- NonTerminating: A non-terminating error is generated
		Default: Terminating
	
	.PARAMETER ProviderName
		Name of the provider generating the items.
		Defaults to: FileSystem
	
	.PARAMETER Cmdlet
		The $PSCmdlet object representing the calling command
		If this parameter is specified, the error is executed in the context of the calling command, not Resolve-PSFItem.
	
	.EXAMPLE
		PS C:\> Resolve-PSFItem -Path $Path -LiteralPath $LiteralPath -Cmdlet $PSCmdlet
		
		Searches all items found under the specified paths.

	.EXAMPLE
		PS C:\> Resolve-PSFItem -Path $Path -Type File -ResolutionMode AtLeastOne -WarningMode None -Cmdlet $PSCmdlet

		Searches for all files under $Path.
		No warning will ever be generated, but at least one file must be found, otherwise the calling command is killed with a terminating exception.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	param (
		[AllowNull()]
		[AllowEmptyCollection()]
		[string[]]
		$Path,

		[AllowNull()]
		[AllowEmptyCollection()]
		[string[]]
		$LiteralPath,

		[ValidateSet('Any', 'File', 'Directory', 'Leaf', 'Container')]
		[string]
		$Type = 'Any',

		[ValidateSet('Any', 'All', 'AtLeastOne', 'OnlyOne')]
		[string]
		$ResolutionMode = 'Any',

		[ValidateSet('None', 'One', 'All')]
		[string]
		$WarningMode = 'One',

		[ValidateSet('Terminating', 'NonTerminating')]
		[string]
		$ErrorMode = 'Terminating',

		[PsfArgumentCompleter('PSFramework-utility-psprovider')]
		[string]
		$ProviderName = 'FileSystem',

		$Cmdlet
	)
	begin {
		#region Filters
		$filters = @{
			'Any'       = { $_.PSProvider.Name -eq $ProviderName }
			'File'      = {
				$_.PSProvider.Name -eq $ProviderName -and
				-not $_.PSIsContainer
			}
			'Leaf'      = {
				$_.PSProvider.Name -eq $ProviderName -and
				-not $_.PSIsContainer
			}
			'Directory' = {
				$_.PSProvider.Name -eq $ProviderName -and
				$_.PSIsContainer
			}
			'Container' = {
				$_.PSProvider.Name -eq $ProviderName -and
				$_.PSIsContainer
			}
		}
		#endregion Filters
	}
	process {
		#region Process Paths
		$badPaths = [System.Collections.ArrayList]@()
		$foundItems = [System.Collections.ArrayList]@()
		foreach ($entry in $Path) {
			$results = Get-Item -Path $entry -ErrorAction Ignore | Where-Object $filters[$Type]
			Write-PSFMessage -Level Debug -String 'Resolve-PSFItem.Path.Found' -StringValues $entry, @($results).Count -Target $entry
			if ($results) { $null = $foundItems.AddRange(@($results)) }
			else { $null = $badPaths.Add($entry) }
		}

		foreach ($entry in $LiteralPath) {
			$results = Get-Item -LiteralPath $entry -ErrorAction Ignore | Where-Object $filters[$Type]
			Write-PSFMessage -Level Debug -String 'Resolve-PSFItem.Path.Found' -StringValues $entry, @($results).Count -Target $entry
			if ($results) { $null = $foundItems.AddRange(@($results)) }
			else { $null = $badPaths.Add($entry) }
		}
		Write-PSFMessage -Level Debug -String 'Resolve-PSFItem.Path.Summary' -StringValues (@($Path).Count + @($LiteralPath).Count), $foundItems.Count, $badPaths.Count
		#endregion Process Paths

		#region Process Warnings
		if ($badPaths) {
			switch ($WarningMode) {
				'One' {
					Write-PSFMessage -Level Warning -String 'Resolve-PSFItem.BadPaths' -StringValues ($badPaths -join ', ')
				}
				'All' {
					foreach ($badPath in $badPaths) {
						Write-PSFMessage -Level Warning -String 'Resolve-PSFItem.BadPath' -StringValues $badPath -Target $badPath
					}
				}
			}
		}
		#endregion Process Warnings

		#region Process Error State
		$mustDie = $false
		switch ($ResolutionMode) {
			'All' {
				if ($badPaths) {
					$mustDie = $true
				}
			}
			'AtLeastOne' {
				if (-not $foundItems) {
					$mustDie = $true
				}
			}
			'OnlyOne' {
				if (@($foundItems).Count -ne 1) {
					$mustDie = $true
				}
			}
		}
		$myCmdlet = $Cmdlet
		if (-not $myCmdlet) { $myCmdlet = $PSCmdlet }
		if ($mustDie) {
			$category = [System.Management.Automation.ErrorCategory]::InvalidArgument
			switch ($ErrorMode) {
				'Terminating' {
					$target = $badPaths.ToArray()
					$message = switch ($ResolutionMode) {
						'All' { 'Not all paths could be resolved. Bad input: {0}' -f ($badPaths -join "," ) }
						'AtLeastOne' { 'No item could be found under any specified path' }
						'OnlyOne' {
							if (-not $foundItems) { 'No item could be found under any specified path' }
							else { 'Must resolve to a single item. {0} items found!' -f @($foundItems).Count }
						}
					}
					$record = [PSFramework.Meta.PsfErrorRecord]::new($message, $category, 'InvalidArgument', $target)
					$myCmdlet.ThrowTerminatingError($record)
				}
				'NonTerminating' {
					if ($ResolutionMode -eq 'OnlyOne' -and @($foundItems).Count -gt 1) {
						$goodPaths1 = $Path | Where-Object { $_ -notin $badPaths }
						$goodPaths2 = $LiteralPath | Where-Object { $_ -notin $badPaths }

						$message = 'Must resolve to a single item. {0} items found!' -f @($foundItems).Count
						$record = [PSFramework.Meta.PsfErrorRecord]::new($message, $category, 'InvalidArgument', (@($goodPaths1) + @($goodPaths2)))
						$myCmdlet.WriteError($record)
						break
					}

					foreach ($entry in $badPaths) {
						$message = 'No item found under {0}' -f $entry
						$record = [PSFramework.Meta.PsfErrorRecord]::new($message, $category, 'InvalidArgument', $entry)
						$myCmdlet.WriteError($record)
					}
				}
			}
		}
		#endregion Process Error State
		
		$foundItems
	}
}