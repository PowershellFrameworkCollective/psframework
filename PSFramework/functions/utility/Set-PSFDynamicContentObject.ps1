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
	
	.EXAMPLE
		PS C:\> Set-PSFDynamicContentObject -Name Test -Value $Value
	
		Sets the Dynamic Content Object named "test" to the value $Value.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Utility.DynamicContentObject[]]
		$Object,
		
		[Parameter(Mandatory = $true)]
		[AllowNull()]
		$Value
	)
	
	begin
	{
		
	}
	process
	{
		foreach ($item in $Name)
		{
			[PSFramework.Utility.DynamicContentObject]::Set($item, $Value)
		}
		
		foreach ($item in $Object)
		{
			$item.Value = $Value
		}
	}
	end
	{
	
	}
}