function Register-PSFMessageColorTransform {
	<#
	.SYNOPSIS
		Adds a rule that changes the color of messages when applicable.
	
	.DESCRIPTION
		Adds a rule that changes the color of messages when applicable.
		This only affects messages that are shown to the user through the information levels.
		Verbose messages, debug messages or waranings are unaffected, as their color is determined by the system.

		Inline color assignments beat this color transformation.
	
	.PARAMETER Name
		Name of the rule.
		Must be unique and should tell the user where it comes from.
	
	.PARAMETER Color
		The color to apply to the message.
	
	.PARAMETER Priority
		The priority of a color assignment determines, which rule wins when multiple registered transformation rules apply.
		The lower the number, the higher the precedence and the better the chance for the color to apply.
		Defaults to: 50
	
	.PARAMETER Level
		Applies only to messages of the specified level
	
	.PARAMETER MinLevel
		Applies to all messages that have at least this level.
		Note: The lower the level, the higher the default visibility. Users usually see levels 1-3.
	
	.PARAMETER MaxLevel
		Applies to all messages that have no higher level than this.
		Note: The lower the level, the higher the default visibility. Users usually see levels 1-3.
	
	.PARAMETER IncludeTags
		A message must contain at least one of these tags in order to be colored.
	
	.PARAMETER ExcludeTags
		A message may not contain any of these tags in order to be colored.
	
	.PARAMETER IncludeModules
		A message must come from one of these modules in order to be colored.
	
	.PARAMETER ExcludeModules
		A message must not come from one of these modules in order to be colored.
	
	.PARAMETER IncludeFunctions
		A message must come from one of these functions in order to be colored.
	
	.PARAMETER ExcludeFunctions
		A message must not come from one of these functions in order to be colored.
	
	.EXAMPLE
		PS C:\> Register-PSFMessageColorTransform -Name 'PSFramework.Critical' -IncludeModules PSFramework -Level Critical -Color Magenta
		
		Critical messages written from any command in PSFramework will be written in Magenta by default.
	#>
	[CmdletBinding(DefaultParameterSetName = 'default')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[ConsoleColor]
		$Color,

		[int]
		$Priority = 50,

		[Parameter(ParameterSetName = 'Level')]
		[PSFramework.Message.MessageLevel]
		$Level,

		[Parameter(ParameterSetName = 'Range')]
		[ValidateRange(1,9)]
		[int]
		$MinLevel,

		[Parameter(ParameterSetName = 'Range')]
		[ValidateRange(1,9)]
		[int]
		$MaxLevel,

		[string[]]
		$IncludeTags,

		[string[]]
		$ExcludeTags,

		[string[]]
		$IncludeModules,

		[string[]]
		$ExcludeModules,

		[string[]]
		$IncludeFunctions,

		[string[]]
		$ExcludeFunctions
	)
	begin {
		if ($Level -in 'Warning','Error') {
			Stop-PSFFunction -String 'Register-PSFMessageColorTransform.Level.Invalid' -StringValues $Level -EnableException $true -Cmdlet $PSCmdlet
		}
	}
	process {
		$condition = [PSFramework.Message.MessageColorCondition]::new($Name, $Color)
		
		$condition.Priority = $Priority
		if ($MinLevel) { $condition.MinLevel = $MinLevel }
		if ($MaxLevel) { $condition.MaxLevel = $MaxLevel }
		if ($Level) {
			$condition.Minlevel = [int]$Level
			$condition.MaxLevel = [int]$Level
		}
		if ($IncludeTags) { $condition.IncludeTags = $IncludeTags }
		if ($ExcludeTags) { $condition.ExcludeTags = $ExcludeTags }
		if ($IncludeModules) { $condition.IncludeModules = $IncludeModules }
		if ($ExcludeModules) { $condition.ExcludeModules = $ExcludeModules }
		if ($IncludeFunctions) { $condition.IncludeFunctions = $IncludeFunctions }
		if ($ExcludeFunctions) { $condition.ExcludeFunctions = $ExcludeFunctions }

		[PSFramework.Message.MessageHost]::ColorTransforms[$Name] = $condition
	}
}