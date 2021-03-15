function Get-PSFScriptblock
{
<#
	.SYNOPSIS
		Access the scriptblocks stored with Set-PSFScriptblock.
	
	.DESCRIPTION
		Access the scriptblocks stored with Set-PSFScriptblock.
	
		Use this command to access scriptblocks designed for easy, processwide access.
	
	.PARAMETER Name
		The name of the scriptblock to request.
		It's mandatory for explicitly requesting a scriptblock, but optional to use with -List as a filter.
	
	.PARAMETER List
		Instead of requesting a specific scriptblock, list the available ones.
		This can be further filtered by using a wildcard supporting string as -Name.

	.PARAMETER Tag
		Filter scriptblocks by their tags.
		This can be further filtered by using a wildcard supporting string as -Name.

	.PARAMETER Description
		Filter scriptblocks by their description using wildcard characters.
		This can be further filtered by using a wildcard supporting string as -Name.
	
	.PARAMETER Container
		Return the scriptblock container item rather than the scriptblock directly.
	
	.EXAMPLE
		PS C:\> Get-PSFScriptblock -Name 'MyModule.TestServer'
	
		Returns the scriptblock stored as 'MyModule.TestServer'
	
	.EXAMPLE
		PS C:\> Get-PSFScriptblock -List
	
		Returns a list of all scriptblocks
	
	.EXAMPLE
		PS C:\> Get-PSFScriptblock -List -Name 'MyModule.TestServer'
	
		Returns scriptblock and meta information for the MyModule.TestServer scriptblock.
	
	.EXAMPLE
		PS C:\> Get-PSFScriptblock -Name 'MyModule.*' -Tag StateChanging, Networking
	
		Returns scriptblock and meta information for all scriptblocks tagged StateChanging
		or Networking and with a name starting with MyModule.
	
	.EXAMPLE
		PS C:\> Get-PSFScriptblock -Description '*Infrastructure Script*'
	
		Returns scriptblock and meta information for all script blocks containing the
		description '*Infrastructure Script*'.
#>
	[OutputType([PSFramework.Utility.ScriptBlockItem], ParameterSetName = 'Search')]
	[OutputType([PSFramework.Utility.ScriptBlockItem], ParameterSetName = 'Container')]
	[OutputType([System.Management.Automation.ScriptBlock], ParameterSetName = 'Name')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[PsfArgumentCompleter('PSFramework.Utility.Scriptblock.Name')]
		[Parameter(ParameterSetName = 'Search', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Parameter(Mandatory = $true, ParameterSetName = 'Name', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Parameter(Mandatory = $true, ParameterSetName = 'Container', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name = '*',
		
		[Parameter(ParameterSetName = 'Search')]
		[switch]
		$List,

		[Parameter(ParameterSetName = 'Search')]
		[string]
		$Description,
		
		[PsfArgumentCompleter('PSFramework.Utility.Scriptblock.Tag')]
		[Parameter(ParameterSetName = 'Search')]
		[string[]]
		$Tag,
		
		[Parameter(ParameterSetName = 'Container')]
		[switch]
		$Container
	)
	
	begin
	{
		[System.Collections.ArrayList]$sent = @()
		$allItems = [PSFramework.Utility.UtilityHost]::ScriptBlocks.Values
	}
	process
	{
		:main foreach ($nameText in $Name)
		{
			switch ($PSCmdlet.ParameterSetName) {
				#region Retrieve by name
				{ 'Name', 'Container' -contains $_ }
				{
					if ($sent -contains $nameText) { continue main }
					$null = $sent.Add($nameText)
					$scriptBlock = [PSFramework.Utility.UtilityHost]::ScriptBlocks[$nameText]
					if (-not $scriptBlock) { continue main }
					# If not available in the current runspace, skip it
					if (-not $scriptBlock.IsAvailable()) { continue main }
					if ($Container) { $scriptBlock }
					else { $scriptBlock.ScriptBlock }
				}
				#endregion Retrieve by name
				#region Search by filters
				'Search'
				{
					foreach ($item in $allItems) {
						# If not available in the current runspace, skip it
						if (-not $item.IsAvailable()) { continue }
						
						if ($item.Name -notlike $nameText) { continue }
						if ($sent -contains $item.Name) { continue }
						
						if ($Tag) {
							$found = $false
							foreach ($tagString in $Tag) {
								if ($item.Tag -contains $tagString) { $found = $true }
							}
							if (-not $found) { continue }
						}
						if ($Description -and $item.Description -notlike $Description) { continue }
						
						$null = $sent.Add($item.Name)
						$item
					}
				}
				#endregion Search by filters
			}
		}
	}
}