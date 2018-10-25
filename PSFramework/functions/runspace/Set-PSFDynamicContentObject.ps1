function Set-PSFDynamicContentObject
{
<#
	.SYNOPSIS
		Updates a value object that can easily be accessed on another runspace.
	
	.DESCRIPTION
		Updates a value object that can easily be accessed on another runspace.
		
		The Dynamic Content Object system allows the user to easily have the content of a variable updated in the background.
		The update is performed by this very function.
	
	.PARAMETER Name
		The name of the value to update.
		Not case sensitive.
	
	.PARAMETER Object
		The value object to update
	
	.PARAMETER Value
		The value to apply
	
	.PARAMETER Queue
		Set the object to be a threadsafe queue.
		Safe to use in multiple runspaces in parallel.
		Will not apply changes if the current value is already such an object.
	
	.PARAMETER Stack
		Set the object to be a threadsafe stack.
		Safe to use in multiple runspaces in parallel.
		Will not apply changes if the current value is already such an object.
	
	.PARAMETER List
		Set the object to be a threadsafe list.
		Safe to use in multiple runspaces in parallel.
		Will not apply changes if the current value is already such an object.
	
	.PARAMETER Dictionary
		Set the object to be a threadsafe dictionary.
		Safe to use in multiple runspaces in parallel.
		Will not apply changes if the current value is already such an object.
	
	.EXAMPLE
		PS C:\> Set-PSFDynamicContentObject -Name Test -Value $Value
		
		Sets the Dynamic Content Object named "test" to the value $Value.
	
	.EXAMPLE
		PS C:\> Set-PSFDynamicContentObject -Name MyModule.Value -Queue
	
		Sets the Dynamic Content Object named "MyModule.Value" to contain a threadsafe queue.
		This queue will be safe to enqueue and dequeue from, no matter the number of runspaces accessing it simultaneously.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Utility.DynamicContentObject[]]
		$Object,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Value')]
		[AllowNull()]
		$Value = $null,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Queue')]
		[switch]
		$Queue,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Stack')]
		[switch]
		$Stack,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'List')]
		[switch]
		$List,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Dictionary')]
		[switch]
		$Dictionary
	)
	
	process
	{
		foreach ($item in $Name)
		{
			if (Test-PSFParameterBinding -ParameterName Value) { [PSFramework.Utility.DynamicContentObject]::Set($item, $Value) }
			if ($Queue) { [PSFramework.Utility.DynamicContentObject]::Get($item).ConcurrentQueue() }
			if ($Stack) { [PSFramework.Utility.DynamicContentObject]::Get($item).ConcurrentStack() }
			if ($List) { [PSFramework.Utility.DynamicContentObject]::Get($item).ConcurrentList() }
			if ($Dictionary) { [PSFramework.Utility.DynamicContentObject]::Get($item).ConcurrentDictionary() }
		}
		
		foreach ($item in $Object)
		{
			$item.Value = $Value
			if ($Queue) { $item.ConcurrentQueue() }
			if ($Stack) { $item.ConcurrentStack() }
			if ($List) { $item.ConcurrentList() }
			if ($Dictionary) { $item.ConcurrentDictionary() }
		}
	}
}