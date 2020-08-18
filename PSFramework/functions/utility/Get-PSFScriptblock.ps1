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
	
	.EXAMPLE
		PS C:\> Get-PSFScriptblock -Name 'MyModule.TestServer'
	
		Returns the scriptblock stored as 'MyModule.TestServer'
	
	.EXAMPLE
		PS C:\> Get-PSFScriptblock -List
	
		Returns a list of all scriptblocks
	
	.EXAMPLE
		PS C:\> Get-PSFScriptblock -List -Name 'MyModule.TestServer'
	
		Returns scriptblock and meta information for the MyModule.TestServer scriptblock.
#>
	[OutputType([PSFramework.Utility.ScriptBlockItem], ParameterSetName = 'List')]
	[OutputType([System.Management.Automation.ScriptBlock], ParameterSetName = 'Name')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(ParameterSetName = 'List')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Name', ValueFromPipeline = $true)]
		[string[]]
		$Name = '*',
		
		[Parameter(Mandatory = $true, ParameterSetName = 'List')]
		[switch]
		$List
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
			switch ($PSCmdlet.ParameterSetName)
			{
				'Name'
				{
					if ($sent -contains $nameText) { continue main }
					$null = $sent.Add($nameText)
					[PSFramework.Utility.UtilityHost]::ScriptBlocks[$nameText].ScriptBlock
				}
				'List'
				{
					foreach ($item in $allItems)
					{
						if ($item.Name -notlike $nameText) { continue }
						if ($sent -contains $item.Name) { continue }
						$null = $sent.Add($item.Name)
						$item
					}
				}
			}
		}
	}
}