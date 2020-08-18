function Register-PSFTeppArgumentCompleter
{
    <#
        .SYNOPSIS
            Registers a parameter for a prestored Tepp.
        
        .DESCRIPTION
            Registers a parameter for a prestored Tepp.
            This function allows easily registering a function's parameter for Tepp in the function-file, rather than in a centralized location.
        
        .PARAMETER Command
            Name of the command whose parameter should receive Tepp.
        
        .PARAMETER Parameter
            Name of the parameter that should be Tepp'ed.
        
        .PARAMETER Name
            Name of the Tepp Completioner to use.
			Use the same name as was assigned in Register-PSFTeppScriptblock (which needs to be called first).
        
        .EXAMPLE
            Register-PSFTeppArgumentCompleter -Command Get-Test -Parameter Example -Name MyModule.Example
    
            Registers the parameter 'Example' of the command 'Get-Test' to receive the tab completion registered to 'MyModule.Example'
    #>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFTeppArgumentCompleter')]
	Param (
		[Parameter(Mandatory = $true)]
		[string[]]
		$Command,
		
		[Parameter(Mandatory = $true)]
		[string[]]
		$Parameter,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Name
	)
	process
	{
		foreach ($Param in $Parameter)
		{
			$scriptBlock = [PSFramework.TabExpansion.TabExpansionHost]::Scripts[$Name].ScriptBlock
			if ([PSFramework.TabExpansion.TabExpansionHost]::Scripts[$Name].InnerScriptBlock)
			{
				[PSFramework.Utility.UtilityHost]::ImportScriptBlock($scriptBlock, $true)
			}
			Register-ArgumentCompleter -CommandName $Command -ParameterName $Param -ScriptBlock $scriptBlock
		}
	}
}