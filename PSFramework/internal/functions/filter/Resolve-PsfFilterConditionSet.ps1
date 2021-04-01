function Resolve-PsfFilterConditionSet
{
<#
	.SYNOPSIS
		Internal helper to consistently resolve the relevant Condition Set.
	
	.DESCRIPTION
		Internal helper to consistently resolve the relevant Condition Set.
		Either by object or module & name combination.
	
	.PARAMETER ConditionSet
		A condition set object to use.
	
	.PARAMETER SetModule
		The name of the module from which to select the condition set to use.
	
	.PARAMETER SetName
		The name of the condition set to use.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command, so that the terminating exception happens in the context of the caller.
	
	.EXAMPLE
		PS C:\> Resolve-PsfFilterConditionSet -ConditionSet $ConditionSet -SetModule $SetModule -SetName $SetName -Cmdlet $Cmdlet
	
		Resolves the Condition Set to use or fails in blood, pain and suffering.
#>
	[OutputType([PSFramework.Filter.ConditionSet])]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[AllowNull()]
		[PSFramework.Filter.ConditionSet]
		$ConditionSet,
		
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$SetModule,
		
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$SetName,
		
		[Parameter(Mandatory = $true)]
		$Cmdlet
	)
	
	process
	{
		$conditionSetObject = $null
		if ($SetModule) {
			$conditionSetObject = $script:filterContainer.GetConditionSet($SetModule, $SetName)
			if (-not $conditionSetObject) {
				Invoke-PsfTerminatingException -Message "Unable to find condition set $SetName in module $SetModule" -ErrorId 'ConditionSetNotFound' -Category InvalidArgument -TargetObject $SetName -Cmdlet $Cmdlet
			}
		}
		if ($ConditionSet) { $conditionSetObject = $ConditionSet }
		if (-not $conditionSetObject) {
			Invoke-PsfTerminatingException -Message "Unable to find condition set" -ErrorId 'ConditionSetNotFound' -Category InvalidArgument -Cmdlet $Cmdlet -TargetObject $null
		}
		$conditionSetObject
	}
}