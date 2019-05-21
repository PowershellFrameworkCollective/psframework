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
			$Result
		)
		
		Write-PSFMessage -String 'Configuration.Schema.MetaJson.ProcessFile' -StringValues $Path -ModuleName PSFramework
		
		$basePath = Split-Path -Path $Path
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
		#endregion Import Resources
		
		#region Import included / linked configuration files
		foreach ($include in $NodeData.Include)
		{
			$resolvedInclude = Resolve-V1String -String $include
			$uri = [uri]$resolvedInclude
			if ($uri.IsAbsoluteUri)
			{
				try
				{
					$newData = Get-Content $resolvedInclude -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
				}
				catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidJson' -StringValues $resolvedInclude -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
				try
				{
					$null = Read-V1Node -NodeData $newData -Result $Result -Path $resolvedInclude
					continue
				}
				catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.NestedError' -StringValues $resolvedInclude -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
			}
			
			$joinedPath = Join-Path -Path $basePath -ChildPath ($resolvedInclude -replace '^\.\\', '\')
			try { $resolvedIncludeNew = Resolve-PSFPath -Path $joinedPath -Provider FileSystem -SingleItem }
			catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.ResolveFile' -StringValues $joinedPath -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
			
			try
			{
				$newData = Get-Content $resolvedIncludeNew -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
			}
			catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidJson' -StringValues $resolvedIncludeNew -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
			try
			{
				$null = Read-V1Node -NodeData $newData -Result $Result -Path $resolvedIncludeNew
				continue
			}
			catch { Stop-PSFFunction -String 'Configuration.Schema.MetaJson.NestedError' -StringValues $resolvedIncludeNew -EnableException $script:EnableException -ModuleName PSFramework -ErrorRecord $_ -Continue -Cmdlet $script:cmdlet }
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
	try { $resolvedPath = Resolve-PSFPath -Path $Resource -Provider FileSystem -SingleItem }
	catch
	{
		Stop-PSFFunction -String 'Configuration.Schema.MetaJson.ResolveFile' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
		return
	}
	
	try { $importData = Get-Content -Path $resolvedPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
	catch
	{
		Stop-PSFFunction -String 'Configuration.Schema.MetaJson.InvalidJson' -StringValues $Resource -ModuleName PSFramework -FunctionName 'Schema: MetaJson' -EnableException $EnableException -ErrorRecord $_ -Cmdlet $script:cmdlet
		return
	}
	#endregion Accessing Content
	
	switch ($importData.Version)
	{
		1
		{
			$configurationHash = Read-V1Node -NodeData $importData -Path $resolvedPath -Result @{ }
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