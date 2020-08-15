function Test-PSFParameterBinding
{
    <#
        .SYNOPSIS
            Helper function that tests, whether a parameter was bound.
        
        .DESCRIPTION
            Helper function that tests, whether a parameter was bound.
        
        .PARAMETER ParameterName
            The name(s) of the parameter that is tested for being bound.
			By default, the check is true when AT LEAST one was bound.
    
        .PARAMETER Not
            Reverses the result. Returns true if NOT bound and false if bound.
	
		.PARAMETER And
			All specified parameters must be present, rather than at least one of them.
	
		.PARAMETER Mode
			Parameters can be explicitly bound or as scriptblocks to be invoked for each item piped to the command.
			The mode determines, which will be tested for.
			Supported Modes: Any, Explicit, PipeScript.
			By default, any will do.
			Whether a parameter was bound as PipeScript is only detectable during the begin block.
        
        .PARAMETER BoundParameters
            The hashtable of bound parameters. Is automatically inherited from the calling function via default value. Needs not be bound explicitly.
        
        .EXAMPLE
            if (Test-PSFParameterBinding "Day")
            {
                
            }
    
            Snippet as part of a function. Will check whether the parameter "Day" was bound. If yes, whatever logic is in the conditional will be executed.
	
		.EXAMPLE
			Test-PSFParameterBinding -Not 'Login', 'Spid', 'ExcludeSpid', 'Host', 'Program', 'Database'
	
			Returns whether none of the parameters above were specified.
	
		.EXAMPLE
			Test-PSFParameterBinding -And 'Login', 'Spid', 'ExcludeSpid', 'Host', 'Program', 'Database'
	
			Returns whether any of the specified parameters was not bound
    #>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFParameterBinding')]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string[]]
		$ParameterName,
		
		[Alias('Reverse')]
		[switch]
		$Not,
		
		[switch]
		$And,
		
		[ValidateSet('Any', 'Explicit', 'PipeScript')]
		[string]
		$Mode = 'Any',
		
		[object]
		$BoundParameters = (Get-PSCallStack)[0].InvocationInfo.BoundParameters
	)
	
	process
	{
		if ($And)
		{
			$test = $true
		}
		else
		{
			$test = $false
		}
		$pipeScriptForbidden = $Mode -eq "Explicit"
		$explicitForbidden = $Mode -eq "PipeScript"
		
		foreach ($name in $ParameterName)
		{
			$isPipeScript = ($BoundParameters.$name.PSObject.TypeNames -eq 'System.Management.Automation.CmdletParameterBinderController+DelayedScriptBlockArgument') -as [bool]
			if ($And)
			{
				if (-not $BoundParameters.ContainsKey($name))
				{
					$test = $false
					continue
				}
				if ($isPipeScript -and $pipeScriptForbidden) { $test = $false }
				if (-not $isPipeScript -and $explicitForbidden) { $test = $false }
				
			}
			else
			{
				if ($BoundParameters.ContainsKey($name))
				{
					if ($isPipeScript -and -not $pipeScriptForbidden) { $test = $true }
					if (-not $isPipeScript -and -not $explicitForbidden) { $test = $true }
				}
			}
		}
		
		return ((-not $Not) -eq $test)
	}
}
if (-not (Test-Path Alias:Was-Bound)) { Set-Alias -Value Test-PSFParameterBinding -Name Was-Bound -Scope Global }