function Write-PSFMessageProxy
{
<#
	.SYNOPSIS
		A proxy command that allows smoothly redirecting messages to Write-PSFMessage.
	
	.DESCRIPTION
		This function is designed to pick up the alias it was called by and to redirect the message that was sent to Write-PSFMessage.
		For example, by creating an alias for Write-Host pointing at 'Write-PSFMessageProxy' will cause it to redirect the message at 'Important' level (which is written to host by default, but also logged).
	
		By creating those aliases, it becomes easy to shift current scripts to use the logging, without having to actually update the code.
	
	.PARAMETER Message
		The message to write.
	
	.EXAMPLE
		PS C:\> Write-PSFMessageProxy "Example Message"
	
		Will write the message "Example Message" to verbose.
	
	.EXAMPLE
		PS C:\> Set-Alias Write-Host Write-PSFMessageProxy
		PS C:\> Write-Host "Example Message"
	
		This will create an alias named "Write-Host" pointing at "Write-PSFMessageProxy".
		Then it will write the message "Example Message", which is automatically written to Level "Important" (which by default will be written to host).
#>
	[CmdletBinding()]
	Param (
		[Parameter(Position = 0)]
		[string]
		$Message
	)
	
	begin
	{
		$call = (Get-PSCallStack)[0].InvocationInfo
		$callStack = (Get-PSCallStack)[1]
		$FunctionName = $callStack.Command
		$ModuleName = $callstack.InvocationInfo.MyCommand.ModuleName
		if (-not $ModuleName) { $ModuleName = "<Unknown>" }
		$File = $callStack.Position.File
		$Line = $callStack.Position.StartLineNumber
		
		$splatParam = @{
			Tag  = 'proxied'
			FunctionName  = $FunctionName
			ModuleName	   = $ModuleName
			File		   = $File
			Line = $Line
		}
	}
	process
	{
		switch ($call.InvocationName)
		{
			"Write-Host" { Write-PSFMessage -Level Important -Message $Message @splatParam }
			"Write-Verbose" { Write-PSFMessage -Level Verbose -Message $Message @splatParam }
			"Write-Warning" { Write-PSFMessage -Level Warning -Message $Message @splatParam }
			"Write-Debug" { Write-PSFMessage -Level System -Message $Message @splatParam }
			"Write-Information" { Write-PSFMessage -Level Important -Message $Message @splatParam }
			default { Write-PSFMessage -Level Verbose -Message $Message @splatParam }
		}
	}
	end
	{
	
	}
}