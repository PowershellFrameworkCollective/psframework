function Get-PSFDynamicContentObject
{
<#
	.SYNOPSIS
		Retrieves a named value object that can be updated from another runspace.
	
	.DESCRIPTION
		Retrieves a named value object that can be updated from another runspace.
	
		This comes in handy to have a variable that is automatically updated.
		Use this function to receive an object under a given name.
		Use Set-PSFDynamicContentObject to update the value of the object.
	
		It matters not from what runspace you update the object.
	
		Note:
		When planning to use such an object, keep in mind that it can easily change its content at any given time.
	
	.PARAMETER Name
		The name of the object to retrieve.
		Will create an empty value object if the object doesn't already exist.
	
	.EXAMPLE
		PS C:\> Get-PSFDynamicContentObject -Name "Test"
	
		Returns the Dynamic Content Object named "test"
#>
	[OutputType([PSFramework.Utility.DynamicContentObject])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFDynamicContentObject')]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($item in $Name)
		{
			[PSFramework.Utility.DynamicContentObject]::Get($item)
		}
	}
}