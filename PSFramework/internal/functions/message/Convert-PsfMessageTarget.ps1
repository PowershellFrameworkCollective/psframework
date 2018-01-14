﻿function Convert-PsfMessageTarget
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
	
	$typeName = $Target.GetType().FullName.ToLower()
	
	if ([PSFramework.Message.MessageHost]::TargetTransforms.ContainsKey($typeName))
	{
		$scriptBlock = [PSFramework.Message.MessageHost]::TargetTransforms[$typeName]
		try
		{
			$tempTarget = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($scriptBlock.ToString())), $null, $null)
			return $tempTarget
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
			$tempTarget = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($transform.ScriptBlock.ToString())), $null, $null)
			return $tempTarget
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Target, "Target", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Target
		}
	}
	
	return $Target
}