﻿function Convert-PsfMessageException
{
	<#
		.SYNOPSIS
			Transforms the Exception input to the message system.
		
		.DESCRIPTION
			Transforms the Exception input to the message system.
		
			If there is an exception running a transformation scriptblock, it will log the error in the transform error queue and return the original object instead.
		
		.PARAMETER Exception
			The input Exception object, that might have to be transformed (may not either)
		
		.PARAMETER FunctionName
			The function writing the message
		
		.PARAMETER ModuleName
			The module, that the function writing the message is part of
		
		.EXAMPLE
			PS C:\> Convert-PsfMessageException -Exception $Exception -FunctionName 'Get-Test' -ModuleName 'MyModule'
		
			Checks internal storage for definitions that require a Exception transform, and either returns the original object or the transformed object.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$Exception,
		
		[Parameter(Mandatory = $true)]
		[string]
		$FunctionName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$ModuleName
	)
	
	if ($null -eq $Exception) { return }
	
	$typeName = $Exception.GetType().FullName.ToLower()
	
	if ([PSFramework.Message.MessageHost]::ExceptionTransforms.ContainsKey($typeName))
	{
		$scriptBlock = [PSFramework.Message.MessageHost]::ExceptionTransforms[$typeName]
		try
		{
			$tempException = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($scriptBlock.ToString())), $null, $Exception)
			return $tempException
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Exception, "Exception", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Exception
		}
	}
	
	if ($transform = [PSFramework.Message.MessageHost]::ExceptionTransformList.Get($typeName, $ModuleName, $FunctionName))
	{
		try
		{
			$tempException = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($transform.ScriptBlock.ToString())), $null, $Exception)
			return $tempException
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Exception, "Target", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Exception
		}
	}
	
	return $Exception
}