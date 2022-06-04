function Invoke-PSFCommand
{
<#
	.SYNOPSIS
		An Invoke-Command wrapper with integrated session management.
	
	.DESCRIPTION
		This wrapper command around Invoke-Command allows conveniently calling remote calls.
	
		- It uses the PSFComputer parameter class, and is thus a lot more flexible in accepted input
		- It automatically reuses sessions specified for input
		- It automatically establishes new sessions, tracks usage and retires sessions that have timed out.
	
		Using this command, it is no longer necessary to first establish a connection and then manually handle the session object.
		Just point the command at the computer and it will remember.
		It also reuses sessions across multiple commands that call it.
	
		Note:
		Special connection conditions (like a custom application name, alternative authentication schemes, etc.) are not supported and require using New-PSSession to establish the connection.
		Once that session has been established, the session object can be used with this command and will be used for command invocation.
	
	.PARAMETER ComputerName
		The computer(s) to invoke the command on.
		Accepts all kinds of things that legally point at a computer, including DNS names, ADComputer objects, IP Addresses, SQL Server connection strings, CimSessions or PowerShell Sessions.
		It will reuse PSSession objects if specified (and not include them in its session management).
	
	.PARAMETER ScriptBlock
		The code to execute.
	
	.PARAMETER ArgumentList
		The arguments to pass into the scriptblock.
	
	.PARAMETER Credential
		Credentials to use when establishing connections.
		Note: These will be ignored if there already exists an established connection.
	
	.PARAMETER HideComputerName
		Indicates that this cmdlet omits the computer name of each object from the output display. By default, the name of the computer that generated the object appears in the display.
	
	.PARAMETER ThrottleLimit
		Specifies the maximum number of concurrent connections that can be established to run this command. If you omit this parameter or enter a value of 0, the default value, 32, is used.
	
	.EXAMPLE
		PS C:\> Invoke-PSFCommand -ScriptBlock $ScriptBlock
	
		Runs the $scriptblock against the local computer.
	
	.EXAMPLE
		PS C:\> Invoke-PSFCommand -ScriptBlock $ScriptBlock (Get-ADComputer -Filter "name -like 'srv-db*'")
	
		Runs the $scriptblock against all computers in AD with a name that starts with "srv-db".
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectUsageOfAssignmentOperator", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Invoke-PSFCommand')]
	param (
		[PSFComputer[]]
		[Alias('Session')]
		$ComputerName = $env:COMPUTERNAME,
		
		[Parameter(Mandatory = $true)]
		[scriptblock]
		$ScriptBlock,
		
		[object[]]
		$ArgumentList,
		
		[System.Management.Automation.CredentialAttribute()]
		[System.Management.Automation.PSCredential]
		$Credential,
		
		[switch]
		$HideComputerName,
		
		[int]
		$ThrottleLimit = 32
	)
	
	begin
	{
		#region Clean up broken sessions
		[array]$broken = $psframework_pssessions.GetBroken()
		foreach ($sessionInfo in $broken)
		{
			Write-PSFMessage -Level Debug -Message "Removing broken session to $($sessionInfo.ComputerName)"
			Remove-PSSession -Session $sessionInfo.Session -ErrorAction Ignore
			$null = $psframework_pssessions.Remove($sessionInfo.ComputerName)
		}
		#endregion Clean up broken sessions
		
		#region Invoke Command Splats
		$paramInvokeCommand = @{
			ScriptBlock	       = $ScriptBlock
			ArgumentList	   = $ArgumentList
			HideComputerName   = $HideComputerName
			ThrottleLimit	   = $ThrottleLimit
		}
		
		$paramInvokeCommandLocal = @{
			ScriptBlock		    = $ScriptBlock
			ArgumentList	    = $ArgumentList
		}
		#endregion Invoke Command Splats
	}
	process
	{
		#region Collect list of sessions to process
		$sessionsToInvoke = @()
		$managedSessions = @()
		
		foreach ($computer in $ComputerName)
		{
			if ($computer.Type -eq "PSSession") { $sessionsToInvoke += $computer.InputObject }
			elseif ($sessionObject = $computer.InputObject -as [System.Management.Automation.Runspaces.PSSession]) { $sessionsToInvoke += $sessionObject }
			else
			{
				#region Handle localhost
				if ($computer.IsLocalHost)
				{
					Write-PSFMessage -Level Verbose -Message "Executing command against localhost" -Target $computer
					Invoke-Command @paramInvokeCommandLocal
					continue
				}
				#endregion Handle localhost
				
				#region Already have a cached session
				if ($session = $psframework_pssessions[$computer.ComputerName])
				{
					$sessionsToInvoke += $session.Session
					$managedSessions += $session
					$session.ResetTimestamp()
				}
				#endregion Already have a cached session
				
				#region Establish new session and add to management
				else
				{
					Write-PSFMessage -Level Verbose -Message "Establishing connection to $computer" -Target $computer
					try
					{
						if ($Credential) { $pSSession = New-PSSession -ComputerName $computer -Credential $Credential -ErrorAction Stop }
						else { $pSSession = New-PSSession -ComputerName $computer -ErrorAction Stop }
					}
					catch
					{
						Write-PSFMessage -Level Warning -Message "Failed to connect to $computer" -ErrorRecord $_ -Target $computer 3>$null
						Write-Error -ErrorRecord $_
						continue
					}
					
					$session = New-Object PSFramework.ComputerManagement.PSSessioninfo($pSSession)
					$psframework_pssessions[$session.ComputerName] = $session
					$sessionsToInvoke += $session.Session
					$managedSessions += $session
				}
				#endregion Establish new session and add to management
			}
		}
		#endregion Collect list of sessions to process
		
		if ($sessionsToInvoke)
		{
			Write-PSFMessage -Level VeryVerbose -Message "Invoking command against $($sessionsToInvoke.ComputerName -join ', ' )"
			Invoke-Command -Session $sessionsToInvoke @paramInvokeCommand
		}
		
		#region Refresh timestamp
		foreach ($session in $managedSessions)
		{
			$session.ResetTimestamp()
		}
		#endregion Refresh timestamp
	}
	end
	{
		#region Cleanup expired sessions
		[array]$expired = $psframework_pssessions.GetExpired()
		foreach ($sessionInfo in $expired)
		{
			Write-PSFMessage -Level Debug -Message "Removing expired session to $($sessionInfo.ComputerName)"
			Remove-PSSession -Session $sessionInfo.Session -ErrorAction Ignore
			$null = $psframework_pssessions.Remove($sessionInfo.ComputerName)
		}
		#endregion Cleanup expired sessions
	}
}