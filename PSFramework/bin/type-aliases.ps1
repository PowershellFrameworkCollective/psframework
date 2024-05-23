# Define our type aliases
$TypeAliasTable = @{
	PsfArgumentCompleter    = "PSFramework.TabExpansion.PsfArgumentCompleterAttribute"
	PSFComputer             = "PSFramework.Parameter.ComputerParameter"
	PSFComputerParameter    = "PSFramework.Parameter.ComputerParameter"
	PSFDateTime             = "PSFramework.Parameter.DateTimeParameter"
	PSFDateTimeParameter    = "PSFramework.Parameter.DateTimeParameter"
	PsfDirectory            = 'PSFramework.Parameter.PathDirectoryParameter'
	PsfDirectoryLax         = 'PSFramework.Parameter.PathDirectoryLaxParameter'
	PsfDynamicTransform     = 'PSFramework.Utility.DynamicTransformationAttribute'
	PSFEncoding             = "PSFramework.Parameter.EncodingParameter"
	PSFEncodingParameter    = "PSFramework.Parameter.EncodingParameter"
	PsfErrorRecord          = 'PSFramework.Meta.PsfErrorRecord'
	PsfFile                 = 'PSFramework.Parameter.PathFileParameter'
	PsfFileLax              = 'PSFramework.Parameter.PathFileLaxParameter'
	PsfHashtable            = 'PSFramework.Utility.PsfHashtable'
	PsfLiteralPath          = 'PSFramework.Parameter.PathLiteralParameter'
	PsfLiteralPathLax       = 'PSFramework.Parameter.PathLiteralLaxParameter'
	PsfNewFile              = 'PSFramework.Parameter.PathNewFileParameter'
	PSFNumber               = 'PSFramework.Utility.Number'
	PsfPath                 = 'PSFramework.Parameter.PathFileSystemParameter'
	PsfPathLax              = 'PSFramework.Parameter.PathFileSystemLaxParameter'
	psfrgx                  = "PSFramework.Utility.RegexHelper"
	PsfScriptBlock          = 'PSFramework.Utility.PsfScriptBlock'
	PsfScriptTransform      = 'PSFramework.Utility.ScriptTransformationAttribute'
	PSFSize                 = "PSFramework.Utility.Size"
	PSFTimeSpan             = "PSFramework.Parameter.TimeSpanParameter"
	PSFTimeSpanParameter    = "PSFramework.Parameter.TimeSpanParameter"
	PsfValidateLanguageMode = "PSFramework.Validation.PsfValidateLanguageMode"
	PSFValidatePattern      = "PSFramework.Validation.PsfValidatePatternAttribute"
	PSFValidatePSVersion    = "PSFramework.Validation.PsfValidatePSVersion"
	PSFValidateScript       = "PSFramework.Validation.PsfValidateScriptAttribute"
	PSFValidateSet          = "PSFramework.Validation.PsfValidateSetAttribute"
}

Set-PSFTypeAlias -Mapping $TypeAliasTable