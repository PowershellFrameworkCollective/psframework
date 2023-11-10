function Register-PSFSupportDataProvider {
	<#
	.SYNOPSIS
		Registers additional data collection logic for the PSFramework Support Package.
	
	.DESCRIPTION
		Registers additional data collection logic for the PSFramework Support Package.
		This allows your module to include its own debugging information for the support package.

		This logic is used in the New-PSFSupportPackage command.
	
	.PARAMETER Name
		Name of the support data provider.
	
	.PARAMETER ScriptBlock
		Code that generates support data.
		Should provide information helpful with troubleshooting your code.
	
	.EXAMPLE
		PS C:\> Register-PSFSupportDataProvider -Name MyModule.MyData -ScriptBlock $code

		Registers the code in $code as a data provider for the support package.
		In case of somebody running the "New-PSFSupportPackage" this code will be executed and its results included in the file.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[scriptblock]
		$ScriptBlock
	)
	process {
		$script:supportDataProviders[$Name] = $ScriptBlock
	}
}