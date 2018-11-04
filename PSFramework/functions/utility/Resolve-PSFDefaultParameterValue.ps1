function Resolve-PSFDefaultParameterValue
{
<#
	.SYNOPSIS
		Used to filter and process default parameter values.
	
	.DESCRIPTION
		This command picks all the default parameter values from a reference hashtable.
		It then filters all that match a specified command and binds them to that specific command, narrowing its focus.
		These get merged into either a new or a specified hashtable and returned.
	
	.PARAMETER Reference
		The hashtable to pick default parameter values from.
	
	.PARAMETER CommandName
		The commands to pick default parameter values for.
	
	.PARAMETER Target
		The target hashtable to merge results into.
		By default an empty hashtable is used.
	
	.PARAMETER ParameterName
		Only resolve for specific parameter names.
	
	.EXAMPLE
		PS C:\> Resolve-PSFDefaultParameterValue -Reference $global:PSDefaultParameterValues -CommandName 'Invoke-WebRequest'
	
		Returns a hashtable containing all default parameter values in the global scope affecting the command 'Invoke-WebRequest'.
#>
	[OutputType([System.Collections.Hashtable])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Resolve-PSFDefaultParameterValue')]
	param (
		[Parameter(Mandatory = $true)]
		[System.Collections.Hashtable]
		$Reference,
		
		[Parameter(Mandatory = $true)]
		[string[]]
		$CommandName,
		
		[System.Collections.Hashtable]
		$Target = @{ },
		
		[string[]]
		$ParameterName = "*"
	)
	
	begin
	{
		$defaultItems = @()
		foreach ($key in $Reference.Keys)
		{
			$defaultItems += [PSCustomObject]@{
				Key	    = $key
				Value   = $Reference[$key]
				Command = $key.Split(":")[0]
				Parameter = $key.Split(":")[1]
			}
		}
	}
	process
	{
		foreach ($command in $CommandName)
		{
			foreach ($item in $defaultItems)
			{
				if ($command -notlike $item.Command) { continue }
				
				foreach ($parameter in $ParameterName)
				{
					if ($item.Parameter -like $parameter)
					{
						if ($parameter -ne "*") { $Target["$($command):$($parameter)"] = $item.Value }
						else { $Target["$($command):$($item.Parameter)"] = $item.Value }
					}
				}
			}
		}
	}
	end
	{
		$Target
	}
}