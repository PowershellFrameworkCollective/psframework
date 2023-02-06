function Convert-PsfMessageTarget
{
	<#
		.SYNOPSIS
			Transforms the target input to the message system.
		
		.DESCRIPTION
			Transforms the target input to the message system.
		
			If there is an exception running a transformation scriptblock, it will log the error in the transform error queue and return the original object instead.
		
		.PARAMETER Target
			The input target object, that might have to be transformed (may not either)
		
		.PARAMETER FunctionName
			The function writing the message
		
		.PARAMETER ModuleName
			The module, that the function writing the message is part of
		
		.EXAMPLE
			PS C:\> Convert-PsfMessageTarget -Target $Target -FunctionName 'Get-Test' -ModuleName 'MyModule'
		
			Checks internal storage for definitions that require a target transform, and either returns the original object or the transformed object.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$Target,
		
		[Parameter(Mandatory = $true)]
		[string]
		$FunctionName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$ModuleName
	)
	
	if ($null -eq $Target) { return }
	
	$typeName = $Target.GetType().FullName
	
	if ([PSFramework.Message.MessageHost]::TargetTransforms.ContainsKey($typeName))
	{
		$scriptBlock = [PsfScriptblock][PSFramework.Message.MessageHost]::TargetTransforms[$typeName]
		try
		{
			$ExecutionContext.InvokeCommand.InvokeScript($false, $scriptBlock.ToGlobal(), $null, $Target)
			return
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Target, "Target", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Target
		}
	}
	
	if ($transform = [PSFramework.Message.MessageHost]::TargetTransformlist.Get($typeName, $ModuleName, $FunctionName))
	{
		try
		{
			$ExecutionContext.InvokeCommand.InvokeScript($false, ([PsfScriptblock]$transform.ScriptBlock).ToGlobal(), $null, $Target)
			return
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Target, "Target", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Target
		}
	}
	
	return $Target
}