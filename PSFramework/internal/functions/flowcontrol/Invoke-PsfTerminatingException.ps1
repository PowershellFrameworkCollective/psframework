function Invoke-PsfTerminatingException
{
<#
	.SYNOPSIS
		Executes a terminating error.
	
	.DESCRIPTION
		Executes a terminating error in the context of the caller.
	
	.PARAMETER Message
		Message to include in the terminating error.
	
	.PARAMETER ErrorId
		Error ID to make part of the error record.
	
	.PARAMETER Category
		The error category.
	
	.PARAMETER TargetObject
		The target of the error.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the caller
	
	.EXAMPLE
		PS C:\> Invoke-PsfTerminatingException -Message 'Failed to do XYZ' -ErrorId 'FatalFail' -Category InvalidOperation -TargetObject $TargetObject -Cmdlet $PSCmdlet
	
		Executes a terminating error in the context of the caller.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Message,
		
		[Parameter(Mandatory = $true)]
		[string]
		$ErrorId,
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ErrorCategory]
		$Category,
		
		[Parameter(Mandatory = $true)]
		$TargetObject,
		
		[Parameter(Mandatory = $true)]
		$Cmdlet
	)
	
	process{
		$exception = switch ("$Category") {
			"InvalidArgument" { New-Object System.ArgumentException($Message) }
			default { New-Object System.Exception($Message) }
		}
		$errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, $ErrorId, $Category, $TargetObject)
		$Cmdlet.ThrowTerminatingError($errorRecord)
	}
}