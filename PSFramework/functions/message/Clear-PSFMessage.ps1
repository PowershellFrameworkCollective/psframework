function Clear-PSFMessage {
<#
	.SYNOPSIS
		Clears the in-memory log of the message system.
	
	.DESCRIPTION
		Clears the in-memory log of the message system.
		Has no effect on written logfiles, table entries, eventlog logs or wherever else you may be logging.
	
	.EXAMPLE
		PS C:\> Clear-PSFMessage
	
		Clears the in-memory log of the message system.
#>
	[CmdletBinding()]
	param ()
	
	process {
		[PSFramework.Message.LogHost]::ClearLog()
	}
}