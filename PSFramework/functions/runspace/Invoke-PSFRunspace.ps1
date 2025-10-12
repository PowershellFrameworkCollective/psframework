function Invoke-PSFRunspace {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[ScriptBlock]
		$ScriptBlock,

		[Parameter(ValueFromPipeline = $true)]
		$InputObject,

		[int]
		$ThrottleLimit = 5,

		[ValidateNotNull()]
		[hashtable]
		$Variables = @{}
	)
	begin {
		$runspaceWrapper = [PSFramework.Runspace.RunspaceWrapper]::new()
		
		$runspaceWrapper.AddVariable($Variables)

		# See usually invisible background streams
		$runspaceWrapper.AddVariable("VerbosePreference", $VerbosePreference)
		$runspaceWrapper.AddVariable("InformationPreference", $InformationPreference)

		$runspaceWrapper.Code = $ScriptBlock
		$runspaceWrapper.ThrottleLimit = $ThrottleLimit
		$runspaceWrapper.Start()
	}
	process {
		$runspaceWrapper.AddTaskBulk(@($InputObject))
		$runspaceWrapper.CollectCurrent($PSCmdlet)
	}
	end {
		$runspaceWrapper.Collect($PSCmdlet)
		$runspaceWrapper.Stop()
	}
}