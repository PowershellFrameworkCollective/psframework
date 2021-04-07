Register-PSFConfigSchema -Name MetaJson -Schema {
	param (
		[string]
		$Resource,
		
		[System.Collections.Hashtable]
		$Settings
	)
	
	Write-PSFMessage -String 'Configuration.Schema.MetaJson.ProcessResource' -StringValues $Resource -ModuleName PSFramework
	
	#region Converting parameters
	$Peek = $Settings["Peek"]
	$ExcludeFilter = $Settings["ExcludeFilter"]
	$IncludeFilter = $Settings["IncludeFilter"]
	$AllowDelete = $Settings["AllowDelete"]
	$script:EnableException = $Settings["EnableException"]
	$script:cmdlet = $Settings["Cmdlet"]
	Set-Location -Path $Settings["Path"]
	$PassThru = $Settings["PassThru"]
	#endregion Converting parameters
	
	#region Utility Function
	function Read-V1Node
	{
		[CmdletBinding()]
		param (
			$NodeData,
			
			[string]
			$Path,
			
			[Hashtable]
			$Result,
			
			[string]
			$Type,
			
			[Hashtable]
			$Settings
		)
		
		Write-PSFMessage -String 'Configuration.Schema.MetaJson.ProcessFile' -StringValues $Path -ModuleName PSFramework
		
		$basePath = switch ($Type) {
			'file' { Split-Path -Path $Path }
			'weblink' { $Path -replace '/[^/]+?$' }
			default { $null }
		}
		
		if ($NodeData.ModuleName) { $moduleName = "{0}." -f $NodeData.ModuleName }
		else { $moduleName = "" }
		
		#region Import Resources
		foreach ($property in $NodeData.Static.PSObject.Properties)
		{
			$Result["$($moduleName)$($property.Name)"] = $property.Value
		}
		foreach ($property in $NodeData.Object.PSObject.Properties)
		{
			$Result["$($moduleName)$($property.Name)"] = $property.Value | ConvertFrom-PSFClixml
		}
		foreach ($property in $NodeData.Dynamic.PSObject.Properties)
		{
			$Result["$($moduleName)$(Resolve-V1String -String $property.Name)"] = Resolve-V1String -String $property.Value
		}
		foreach ($property in $NodeData.Tree.PSObject.Properties) {
			Resolve-V1Tree -Property $property -Result $Result -BaseElement @()
		}
		foreach ($property in $NodeData.DynamicTree.PSObject.Properties) {
			Resolve-V1Tree -Property $property -Result $Result -BaseElement @() -Dynamic $true
		}
		#endregion Import Resources
		
		#region Import included / linked configuration files
		:includes foreach ($include in $NodeData.Include)
		{
			$resolvedInclude = Resolve-V1String -String $include
			$uri = [uri]$resolvedInclude
			
			# Skip relative paths if we do not have a base path to place it relative to
			if (-not $uri.IsAbsoluteUri -and -not $basePath) { continue }
			#region Calculate the new include path
			if ($uri.IsAbsoluteUri) { $includePath = $resolvedInclude }
			else {
				$includePath = switch ($Type) {
					'file'
					{
						$joinedPath = Join-Path -Path $basePath -ChildPath ($resolvedInclude -replace '^\.\\', '\')
						try { Resolve-PSFPath -Path $joinedPath -Provider FileSystem -SingleItem }
						catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.ResolveFile' -StringValues $joinedPath -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -ContinueLabel includes -Cmdlet $script:cmdlet }
					}
					'weblink'
					{
						$newPath = $basePath
						$relParts = $resolvedInclude -split "/"
						foreach ($part in $relParts) {
							if ($part -eq '..') { $newPath = $newPath -replace '/[^/]+$' }
							else { $newPath = $newPath, $part -join '/' }
						}
						$newPath
					}
				}
			}
			#endregion Calculate the new include path
			
			$newSettings = $Settings | ConvertTo-PSFHashtable -Include ExcludeFilter, IncludeFilter
			try { $configData = Import-PSFConfig -Path $includePath -Peek @newSettings -Schema MetaJson -EnableException -ErrorAction Stop }
			catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.ExecuteInclude.Error' -StringValues $includePath -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -ContinueLabel includes -Cmdlet $script:cmdlet }
			foreach ($configDatum in $configData) {
				$Result[$configDatum.FullName] = $configDatum.Value
			}
		}
		#endregion Import included / linked configuration files
		
		$Result
	}
	
	function Resolve-V1String
	{
	<#
		.SYNOPSIS
			Resolves a string by inserting placeholders for environment variables.
		
		.DESCRIPTION
			Resolves a string by inserting placeholders for environment variables.
		
		.PARAMETER String
			The string to resolve.
		
		.EXAMPLE
			PS C:\> Resolve-V1String -String '.\%COMPUTERNAME%\config.json'
		
			Resolves the specified string, inserting the local computername for %COMPUTERNAME%.
	#>
		[CmdletBinding()]
		param (
			$String
		)
		if ($String -isnot [string]) { return $String }
		
		$scriptblock = {
			param (
				$Match
			)
			
			$script:envData[$Match.Value]
		}
		
		[regex]::Replace($String, $script:envDataNamesRGX, $scriptblock)
	}
	
	function Resolve-V1Tree {
		[CmdletBinding()]
		param (
			$Property,
			
			[Hashtable]
			$Result,
			
			[bool]
			$Dynamic,
			
			[AllowEmptyCollection()]
			[string[]]
			$BaseElement
		)
		
		if ($Property.TypeNameOfValue -notin 'System.Management.Automation.PSCustomObject', 'System.Collections.Hashtable') {
			$name = (@($BaseElement) + @($Property.Name)) -join "."
			if ($Dynamic) { $Result[(Resolve-V1String -String $name)] = Resolve-V1String -String $Property.Value }
			else { $Result[$name] = $Property.Value }
			return
		}
		
		$value = $Property.Value
		if ($value -is [System.Collections.Hashtable]) { $value = [pscustomobject]$value }
		
		if ($value.'!Condition') {
			$conditionSet = $null
			if ($value.'!ConditionSet') {
				$module, $name = $value.'!ConditionSet' -split ' ', 2
				$conditionSet = Get-PSFFilterConditionSet -Module $module -Name $name | Select-Object -First 1
			}
			else {
				$conditionSet = Get-PSFFilterConditionSet -Module PSFramework -Name Environment
			}
			if (-not $conditionSet) { throw "Unable to resolve Condition Set: $($value.'!ConditionSet')" }
			$filter = New-PSFFilter -Expression $value.'!Condition' -ConditionSet $conditionSet
			if (-not $filter.Evaluate()) { return }
		}
		
		foreach ($propertyObject in $value.PSObject.Properties) {
			if ($propertyObject.Name -eq '!Condition') { continue }
			if ($propertyObject.Name -eq '!ConditionSet') { continue }
			
			if ($value.'!Condition') { Resolve-V1Tree -Property $propertyObject -Result $Result -Dynamic $Dynamic -BaseElement $BaseElement }
			else { Resolve-V1Tree -Property $propertyObject -Result $Result -Dynamic $Dynamic -BaseElement (@($BaseElement) + @($Property.Name)) }
		}
	}
	#endregion Utility Function
	
	#region Utility Computation
	$script:envData = @{ }
	foreach ($envItem in (Get-ChildItem env:\))
	{
		$script:envData["%$($envItem.Name)%"] = $envItem.Value
	}
	$script:envDataNamesRGX = $script:envData.Keys -join '|'
	#endregion Utility Computation
	
	#region Accessing Content
	try {
		$null = Resolve-PSFPath -Path $Resource -Provider FileSystem -SingleItem
		$resourceType = 'File'
	}
	catch {
		if ($Resource -match '^https{0,1}://') { $resourceType = 'weblink' }
		else { $resourceType = 'Json' }
	}
	switch ($resourceType) {
		#region Weblink
		'weblink'
		{
			try { $importData = Invoke-WebRequest -Uri $Resource -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
			catch {
				Stop-PSFFunction -String 'Configuration.Schema.MetaJson.WebError' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
				return
			}
			$resolvedPath = $Resource
		}
		#endregion Weblink
		#region File
		'file'
		{
			try { $resolvedPath = Resolve-PSFPath -Path $Resource -Provider FileSystem -SingleItem }
			catch {
				Stop-PSFFunction -String 'Configuration.Schema.MetaJson.ResolveFile' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
				return
			}
			
			switch -regex ($resolvedPath) {
				'\.psd1$'
				{
					try { $importData = [pscustomobject](Import-PSFPowerShellDataFile -Path $resolvedPath -ErrorAction Stop) }
					catch {
						Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidPsd1' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
						return
					}
					if ($importData.Static -is [hashtable]) { $importData.Static = [pscustomobject]$importData.Static }
					if ($importData.Object -is [hashtable]) { $importData.Object = [pscustomobject]$importData.Object }
					if ($importData.Dynamic -is [hashtable]) { $importData.Dynamic = [pscustomobject]$importData.Dynamic }
					if ($importData.Tree -is [hashtable]) { $importData.Tree = [pscustomobject]$importData.Tree }
					if ($importData.DynamicTree -is [hashtable]) { $importData.DynamicTree = [pscustomobject]$importData.DynamicTree }
				}
				default
				{
					try { $importData = Get-Content -Path $resolvedPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
					catch {
						Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidJson' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
						return
					}
				}
			}
		}
		#endregion File
		#region Straight Json
		default
		{
			try {
				$importData = $Resource | ConvertFrom-Json -ErrorAction Stop
				$resolvedPath = ''
			}
			catch {
				Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidJson' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
				return
			}
		}
		#endregion Straight Json
	}
	#endregion Accessing Content
	
	switch ($importData.Version)
	{
		1
		{
			$configurationHash = Read-V1Node -NodeData $importData -Path $resolvedPath -Type $resourceType -Result @{ } -Settings $Settings
			$configurationItems = $configurationHash.Keys | ForEach-Object {
				[pscustomobject]@{
					FullName = $_
					Value = $configurationHash[$_]
				}
			}
			
			foreach ($configItem in $configurationItems)
			{
				if ($ExcludeFilter | Where-Object { $configItem.FullName -like $_ }) { continue }
				if ($IncludeFilter -and -not ($IncludeFilter | Where-Object { $configItem.FullName -like $_ })) { continue }
				if ($Peek)
				{
					$configItem
					continue
				}
				
				Set-PSFConfig -FullName $configItem.FullName -Value $configItem.Value -AllowDelete:$AllowDelete -PassThru:$PassThru
			}
		}
		default
		{
			Stop-PSFFunction -String 'Configuration.Schema.MetaJson.UnknownVersion' -StringValues $Resource, $importData.Version -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -Cmdlet $script:cmdlet
			return
		}
	}
}