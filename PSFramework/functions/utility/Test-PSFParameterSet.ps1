function Test-PSFParameterSet {
	<#
	.SYNOPSIS
		Tests, whether the command specified would resolve to the specified parameter set with the parameters provided.
		
	.DESCRIPTION
		Tests, whether the command specified would resolve to the specified parameter set with the parameters provided.
		This compares the parametersets on the command metadata with the names of the parameters you intend to provide,
		then resolves the effective parameterset they would lead to.

		Then compares them to the list of Parametersets provided and returns, whether the resolved parameterset would be one of them.

		Note:
		- If the command would not resolve to a legal parameterset, it will return $false.
		- If the command would not be able to resolve to exactly one parameterset, it will return $false. This takes the DefaultParameterSetName into account. This is true even if the remaining Parametersets would include one or multiple of the looked-for Parametersets.

		In consequence, this command cannot take input by pipeline into account (but specifying the name you would bind by pipeline as if explicit should work in most scenarios).
		This command also cannot reliably evaluate dynamic parameters or Parametersets, as those are determined at runtime, not from Metadata.
	
	.PARAMETER Name
		Name of the command to test Parametersets for.
		WARNING: This may easily fail, if PSFramework cannot find the command (e.g. an internal command of another module).
		For best reliability, use the "-Command" parameter instead.

	.PARAMETER Command
		The command object to evaluate.
		Expects an object as returned by "Get-Command".
		This is the more reliable option as opposed to "-Name" and generally preferred, if slightly less convenient to use.
	
	.PARAMETER Parameters
		The names of the parameters provided to the command.
		These are used to determine, which parameterset would be viable.
	
	.PARAMETER Sets
		The names of the Parametersets to check for.
		If the effective Parameterset is any one of them the command returns $true.
	
	.EXAMPLE
		PS C:\> Test-PSFParameterSet -Name Connect-EntraService -Parameters $param.Keys -Sets 'Browser','DeviceCode'

		Returns whether with the specified parameters, Connect-EntraService would end up using either the 'DeviceCode' or 'Browser' Parameterset.

	.EXAMPLE
		PS C:\> Test-PSFParameterSet -Command (Get-Command -Name Resolve-TaskCredential) -Parameters $param.Keys -Sets 'Certificate'

		Returns whether with the specified parameters, Resolve-TaskCredential would end up using the 'Certificate' Parameterset.
		As the caller is resolving Resolve-TaskCredential before calling Test-PSFParameterSet, the command is resolved within the context of the caller and may be invisible to PSFramework without causing any issues.
	#>
	[OutputType([bool])]
	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
		[string]
		$Name,

		[Parameter(Mandatory = $true, ParameterSetName = 'ByCommand')]
		[System.Management.Automation.CommandInfo]
		$Command,
		
		[Parameter(Mandatory = $true)]
		[string[]]
		$Parameters,
		
		[Parameter(Mandatory = $true)]
		[string[]]
		$Sets
	)
	process {
		if ($Command) {
			$commandInfo = $Command
		}
		else {
			try { $commandInfo = Get-Command -Name $Name -ErrorAction Stop }
			catch {
				Stop-PSFFunction -String 'Test-PSFParameterSet.Error.FailedToResolve' -StringValues $Name -EnableException $true -Cmdlet $PSCmdlet -Target $Name
			}
		}
		if ($commandInfo -is [System.Management.Automation.AliasInfo]) {
			$commandInfo = $commandInfo.ResolvedCommand
		}
		if ($null -eq $commandInfo) {
			Stop-PSFFunction -String 'Test-PSFParameterSet.Error.AliasNullTarget' -StringValues $commandInfo.Name, $commandInfo.Definition -EnableException $true -Cmdlet $PSCmdlet -Target $commandInfo
		}
		if ($commandInfo -isnot [System.Management.Automation.CmdletInfo] -and $commandInfo -isnot [System.Management.Automation.FunctionInfo]) {
			Stop-PSFFunction -String 'Test-PSFParameterSet.Error.BadCommandType' -StringValues $commandInfo.Name, $commandInfo.CommandType -EnableException $true -Cmdlet $PSCmdlet -Target $commandInfo
		}

		[PSFramework.Utility.UtilityHost]::TestParameterSetAny($commandInfo, $Parameters, $Sets)
	}
}