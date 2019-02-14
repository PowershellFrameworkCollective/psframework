function New-PSFSessionContainer
{
<#
	.SYNOPSIS
		Creates an object containing multiple session objects to the same computer.
	
	.DESCRIPTION
		Creates an object containing multiple session objects to the same computer.
		Using this, a single object can be used to point at a computer while containing session objects for multiple protocols inside.
	
		Only session types registered via Reigster-PSSessionObjectType are supported.
	
	.PARAMETER ComputerName
		The name of the computer to connect to
	
	.PARAMETER Session
		The session objects that are a live connection to the host.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> New-PSFSessionContainer -ComputerName "server1" -Session $pssession, $cimsession, $smosession
	
		Create a session container containing three different kinds of session objects
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectUsageOfAssignmentOperator", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PSFComputer]
		$ComputerName,
		
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[object[]]
		$Session,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		$container = New-Object PSFramework.ComputerManagement.SessionContainer
		$container.ComputerName = $ComputerName
	}
	process
	{
		foreach ($sessionItem in $Session)
		{
			if ($null -eq $sessionItem) { continue }
			
			if (-not ($sessionName = [PSFramework.ComputerManagement.ComputerManagementHost]::KnownSessionTypes[$sessionItem.GetType()]))
			{
				Stop-PSFFunction -String 'New-PSFSessionContainer.UnknownSessionType' -StringValues $sessionItem.GetType().Name, $sessionItem -Continue -EnableException $EnableException
			}
			
			$container.Connections[$sessionName] = $sessionItem
		}
	}
	end
	{
		$container
	}
}