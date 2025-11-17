function Get-PSFRunspaceLock {
	<#
	.SYNOPSIS
		Create or retrieve a lock object for runspace use.
	
	.DESCRIPTION
		Create or retrieve a lock object for runspace use.
		One of the fundamental features in multi-threading is the "lock":
		A language feature in many programming languages, that helps marshal access to a resource from multiple threads.
		The key goal here: Prevent concurrent access to a resources or process, that cannot be done concurrently.

		PowerShell does not have such a feature.

		This is where the RunspaceLock feature comes in:
		This command generates an object, that can take over the role of the lock-feature in a PowerShell environment!

		First create a lock object:
		$lock = Get-PSFRunspaceLock -Name 'MyModule.Example'

		Then you can obtain the lock calling the Open() method:
		$lock.Open()
		This will reserve the lock for the current runspace.
		If another runspace tries to also call Open(), they will be forced to wait until the current runspace releases the lock.

		Finally, to release the lock, call the Close() method:
		$lock.Close()

		Example implementation:
		$lock = Get-PSFRunspaceLock -Name 'MyModule.ExchangeConnect'
		$lock.Open()
		try { Connect-IPPSSession }
		finally { $lock.Close() }

		This will guarantee, that only one runspace will call "Connect-IPPSSession" at a time, assuming all run this snippet.
	
	.PARAMETER Name
		The name of the runspace-lock.
		No matter from which runspace, all instances using the same name utilize the same lock and can block each other.
	
	.PARAMETER Timeout
		How long a lock is valid for at most.
		By default, a lock is valid for 30 seconds, after which it will expire and be released, in order to prevent permanent lockout / deadlock.
		Increase this if more time is needed, setting this to 0 or less will remove the timeout.
	
	.PARAMETER Unmanaged
		By default, retrieving a lock with the same name will grant access to the exact same lock.
		This makes it easy to use in casual runspace scenarios:
		Simply call Get-PSFRunspaceLock in each runspace with the same name and you are good.
		By making the lock unmanaged, you remove it from this system - the lock-object will not be tracked by PSFramework,
		creating additional instances with the same name will NOT reference the same lock.
		In return, you can safely pass in the lock object to whatever runspace you want with a guarantee to not conflict with anything else.
		This parameter should generally not be needed for most scenarios.
	
	.EXAMPLE
		PS C:\> $lock = Get-PSFRunspaceLock -Name 'MyModule.ExchangeConnect'

		Creates a new lock object named 'MyModule.ExchangeConnect'

	.EXAMPLE
		1..20 | Invoke-PSFRunspace {
			if (-not $global:connected) {
				$lock = Get-PSFRunspaceLock -Name MyModule.ExchangeConnect
				$lock.Open('5m')
				try { Connect-IPPSSession }
				finally { $lock.Close() }
				$global:connected = $true
			}
			Get-Label
		} -ThrottleLimit 4

		In four background runspaces, it will savely connect to Purview and retrieve labels 20 times total, without getting into conflict.
	#>
	[OutputType([PSFramework.Runspace.RunspaceLock])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[PsfTimeSpan]
		$Timeout,

		[switch]
		$Unmanaged
	)
	process {
		if ($Unmanaged) {
			$lock = [PSFramework.Runspace.RunspaceLock]::new($Name)
		}
		else {
			$lock = [PSFramework.Runspace.RunspaceHost]::GetRunspaceLock($Name)
		}
		if ($Timeout) {
			$lock.MaxLockTime = $Timeout.Value.TotalMilliseconds
		}
		$lock
	}
}