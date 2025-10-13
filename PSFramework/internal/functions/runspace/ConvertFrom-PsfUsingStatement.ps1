function ConvertFrom-PsfUsingStatement {
	<#
	.SYNOPSIS
		Removes all using statements from a scriptblock.
	
	.DESCRIPTION
		Removes all using statements from a scriptblock.
		Will return an object with two pieces of information:

		+ Code: The original scriptblock, just with all $using:-statements replaced with simple variable names.
		+ Variables: A deduplicated list of all variables used by the scriptblock, that used to be covered under a $using:-Statement
	
	.PARAMETER ScriptBlock
		The scriptblock to remove $using:-statements from.
	
	.EXAMPLE
		PS C:\> ConvertFrom-PsfUsingStatement -ScriptBlock $code

		Removes all $using:-statements from $code
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ScriptBlock]
		$ScriptBlock
	)
	process {
		$allUsings = $ScriptBlock.Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.UsingExpressionAst] }, $true)
		$varNames = $allUsings.SubExpression.VariablePath.UserPath | Microsoft.PowerShell.Utility\Sort-Object -Unique

		$scriptBlockText = $ScriptBlock.Ast.Extent.Text
		$offset = $ScriptBlock.Ast.Extent.StartOffset
		foreach ($usingInstance in $allUsings | Microsoft.PowerShell.Utility\Sort-Object { $_.Extent.StartOffset } -Descending) {
			$scriptBlockText = $scriptBlockText.SubString(0, ($usingInstance.Extent.StartOffset - $offset)) + "`${$($usingInstance.SubExpression.VariablePath.UserPath)}" + $scriptBlockText.Substring(($usingInstance.Extent.EndOffset - $offset))
		}

		$code = [PsfScriptBlock]::new([scriptblock]::Create($scriptBlockText), $true) -as [scriptblock]
		[PSFramework.Utility.UtilityHost]::SetPrivateProperty("LanguageMode", $code, ([PsfScriptBlock]$ScriptBlock).LanguageMode)

		[PSCustomObject]@{
			Variables = $varNames
			Code = $code
		}
	}
}