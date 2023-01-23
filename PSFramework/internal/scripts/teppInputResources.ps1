[PSFramework.TabExpansion.TabExpansionHost]::InputCompletionTypeData['System.IO.FileInfo'] = @(
	[PSCustomObject]@{
		Name      = 'PSChildName'
		Type      = ([type]'System.String')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSDrive'
		Type      = ([type]'System.Management.Automation.PSDriveInfo')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSIsContainer'
		Type      = ([type]'System.Boolean')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSParentPath'
		Type      = ([type]'System.String')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSPath'
		Type      = ([type]'System.String')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSProvider'
		Type      = ([type]'System.Management.Automation.ProviderInfo')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'BaseName'
		Type      = ([type]'System.String')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'VersionInfo'
		Type      = ([type]'System.Diagnostics.FileVersionInfo')
		TypeKnown = $true
	}
)

[PSFramework.TabExpansion.TabExpansionHost]::InputCompletionTypeData['System.IO.DirectoryInfo'] = @(
	[PSCustomObject]@{
		Name      = 'PSChildName'
		Type      = ([type]'System.String')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSDrive'
		Type      = ([type]'System.Management.Automation.PSDriveInfo')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSIsContainer'
		Type      = ([type]'System.Boolean')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSParentPath'
		Type      = ([type]'System.String')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSPath'
		Type      = ([type]'System.String')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'PSProvider'
		Type      = ([type]'System.Management.Automation.ProviderInfo')
		TypeKnown = $true
	},
	[PSCustomObject]@{
		Name      = 'BaseName'
		Type      = ([type]'System.String')
		TypeKnown = $true
	}
)