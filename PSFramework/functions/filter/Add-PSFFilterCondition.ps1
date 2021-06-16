function Add-PSFFilterCondition
{
<#
	.SYNOPSIS
		Add a filter Condition to a Condition Set.
	
	.DESCRIPTION
		Add a filter Condition to a Condition Set.
	
	.PARAMETER ConditionSet
		The Condition Set object to add to.
	
	.PARAMETER SetModule
		Module of the Condition Set to which to add to.
	
	.PARAMETER SetName
		Name of the Condition Set to which to add to.
	
	.PARAMETER Condition
		The condition object to add to the Condition Set.
	
	.PARAMETER Name
		Name of the Condition to add to the Condition Set.
	
	.PARAMETER Module
		Name of the Module the Condition being added comes from.
		Defaults to the Module of the Condition Set if not specified
	
	.EXAMPLE
		PS C:\> Add-PSFFilterCondition -ConditionSet $barFilter -Name 'FromCellar'
		
		Adds the Condition "FromCellar" to the Condition Set stored in $barFilter.
		The Condition is chosen from the same module as the the Condition Set.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = 'ObjectObject')]
		[Parameter(Mandatory = $true, ParameterSetName = 'ObjectName')]
		[PSFramework.Filter.ConditionSet]
		$ConditionSet,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'NameObject')]
		[Parameter(Mandatory = $true, ParameterSetName = 'NameName')]
		[PsfArgumentCompleter('PSFramework.Filter.SetModule')]
		[string]
		$SetModule,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'NameObject')]
		[Parameter(Mandatory = $true, ParameterSetName = 'NameName')]
		[PsfArgumentCompleter('PSFramework.Filter.SetName')]
		[string]
		$SetName,
		
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ObjectObject')]
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NameObject')]
		[PSFramework.Filter.Condition[]]
		$Condition,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'ObjectName')]
		[Parameter(Mandatory = $true, ParameterSetName = 'NameName')]
		[PsfArgumentCompleter('PSFramework.Filter.Name')]
		[string[]]
		$Name,
		
		[Parameter(ParameterSetName = 'ObjectName')]
		[Parameter(ParameterSetName = 'NameName')]
		[PsfArgumentCompleter('PSFramework.Filter.Module')]
		[string]
		$Module
	)
	
	begin {
		$conditionSetObject = Resolve-PsfFilterConditionSet -ConditionSet $ConditionSet -SetModule $SetModule -SetName $SetName -Cmdlet $PSCmdlet
	}
	process	{
		$moduleName = $Module
		if (-not $moduleName) { $moduleName = $conditionSetObject.Module }
		
		foreach ($conditionName in $Name) {
			foreach ($conditionObject in Get-PSFFilterCondition -Module $moduleName -Name $conditionName) {
				$conditionSetObject.Add($conditionObject)
			}
		}
        foreach ($conditionObject in $Condition) {
            $conditionSetObject.Add($conditionObject)
        }
	}
}