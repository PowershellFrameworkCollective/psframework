# Define our type aliases
$TypeAliasTable = @{
	PSFComputer			   = "PSFramework.Parameter.ComputerParameter"
	PSFComputerParameter   = "PSFramework.Parameter.ComputerParameter"
	PSFDateTime			   = "PSFramework.Parameter.DateTimeParameter"
	PSFDateTimeParameter   = "PSFramework.Parameter.DateTimeParameter"
	psfrgx				   = "PSFramework.Utility.RegexHelper"
	PSFTimeSpan		       = "PSFramework.Parameter.TimeSpanParameter"
	PSFTimeSpanParameter   = "PSFramework.Parameter.TimeSpanParameter"
	PSFValidatePattern     = "PSFramework.Validation.PsfValidatePatternAttribute"
	PSFValidateScript      = "PSFramework.Validation.PsfValidateScriptAttribute"
	PsfValidateSet         = "PSFramework.Validation.PsfValidateSetAttribute"
}

Set-PSFTypeAlias -Mapping $TypeAliasTable