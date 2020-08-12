Register-PSFConfigSchema -Name Default -Schema {
	param (
		[string]
		$Resource,
		
		[System.Collections.Hashtable]
		$Settings
	)
	
	#region Converting parameters
	$Peek = $Settings["Peek"]
	$ExcludeFilter = $Settings["ExcludeFilter"]
	$IncludeFilter = $Settings["IncludeFilter"]
	$AllowDelete = $Settings["AllowDelete"]
	$EnableException = $Settings["EnableException"]
	Set-Location -Path $Settings["Path"]
	$PassThru = $Settings["PassThru"]
	#endregion Converting parameters
	
	#region Utility Function
	function Read-PsfConfigFile
	{
<#
	.SYNOPSIS
		Reads a configuration file and parses it.
	
	.DESCRIPTION
		Reads a configuration file and parses it.
	
	.PARAMETER Path
		The path to the file to parse.
	
	.PARAMETER WebLink
		The link to a website to download straight as raw json.
	
	.PARAMETER RawJson
		Raw json data to interpret.
	
	.EXAMPLE
		PS C:\> Read-PsfConfigFile -Path config.json
	
		Reads the config.json file and returns interpreted configuration objects.
#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true, ParameterSetName = 'Path')]
			[string]
			$Path,
			
			[Parameter(Mandatory = $true, ParameterSetName = 'Weblink')]
			[string]
			$Weblink,
			
			[Parameter(Mandatory = $true, ParameterSetName = 'RawJson')]
			[string]
			$RawJson
		)
		
		#region Utility Function
		function New-ConfigItem
		{
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[CmdletBinding()]
			param (
				$FullName,
				
				$Value,
				
				$Type,
				
				[switch]
				$KeepPersisted,
				
				[switch]
				$Enforced,
				
				[switch]
				$Policy
			)
			
			[pscustomobject]@{
				FullName	  = $FullName
				Value		  = $Value
				Type		  = $Type
				KeepPersisted = $KeepPersisted
				Enforced	  = $Enforced
				Policy	      = $Policy
			}
		}
		
		function Get-WebContent
		{
			[CmdletBinding()]
			param (
				[string]
				$WebLink
			)
			
			$webClient = New-Object System.Net.WebClient
			$webClient.Encoding = [System.Text.Encoding]::UTF8
			$webClient.DownloadString($WebLink)
		}
		#endregion Utility Function
		
		if ($Path)
		{
			if (-not (Test-Path $Path)) { return }
			$data = Get-Content -Path $Path -Encoding UTF8 -Raw | ConvertFrom-Json -ErrorAction Stop
		}
		if ($Weblink)
		{
			$data = Get-WebContent -WebLink $Weblink | ConvertFrom-Json -ErrorAction Stop
		}
		if ($RawJson)
		{
			$data = $RawJson | ConvertFrom-Json -ErrorAction Stop
		}
		
		foreach ($item in $data)
		{
			#region No Version
			if (-not $item.Version)
			{
				New-ConfigItem -FullName $item.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value, $item.Type))
			}
			#endregion No Version
			
			#region Version One
			if ($item.Version -eq 1)
			{
				if ((-not $item.Style) -or ($item.Style -eq "Simple")) { New-ConfigItem -FullName $item.FullName -Value $item.Data }
				else
				{
					if (($item.Type -eq "Object") -or ($item.Type -eq 12))
					{
						New-ConfigItem -FullName $item.FullName -Value $item.Value -Type "Object" -KeepPersisted
					}
					else
					{
						New-ConfigItem -FullName $item.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value, $item.Type))
					}
				}
			}
			#endregion Version One
		}
	}
	#endregion Utility Function
	
	try
	{
		if ($Resource -like "http*") { $data = Read-PsfConfigFile -Weblink $Resource -ErrorAction Stop }
		else
		{
			$pathItem = $null
			try { $pathItem = Resolve-PSFPath -Path $Resource -SingleItem -Provider FileSystem }
			catch { }
			if ($pathItem) { $data = Read-PsfConfigFile -Path $pathItem -ErrorAction Stop }
			else { $data = Read-PsfConfigFile -RawJson $Resource -ErrorAction Stop }
		}
	}
	catch { Stop-PSFFunction -String 'Configuration.Schema.Default.ImportFailed' -StringValues $Resource -EnableException $EnableException -Tag 'fail', 'import' -ErrorRecord $_ -Continue -Target $Resource -Cmdlet $Settings["Cmdlet"] }
	
	:element foreach ($element in $data)
	{
		#region Exclude Filter
		foreach ($exclusion in $ExcludeFilter)
		{
			if ($element.FullName -like $exclusion)
			{
				continue element
			}
		}
		#endregion Exclude Filter
		
		#region Include Filter
		if ($IncludeFilter)
		{
			$isIncluded = $false
			foreach ($inclusion in $IncludeFilter)
			{
				if ($element.FullName -like $inclusion)
				{
					$isIncluded = $true
					break
				}
			}
			
			if (-not $isIncluded) { continue }
		}
		#endregion Include Filter
		
		if ($Peek) { $element }
		else
		{
			try
			{
				if (-not $element.KeepPersisted) { Set-PSFConfig -FullName $element.FullName -Value $element.Value -EnableException -AllowDelete:$AllowDelete -PassThru:$PassThru }
				else { Set-PSFConfig -FullName $element.FullName -PersistedValue $element.Value -PersistedType $element.Type -AllowDelete:$AllowDelete -PassThru:$PassThru }
			}
			catch
			{
				Stop-PSFFunction -String 'Configuration.Schema.Default.SetFailed' -StringValues $element.FullName -ErrorRecord $_ -EnableException $EnableException -Tag 'fail', 'import' -Continue -Target $Resource -Cmdlet $Settings["Cmdlet"]
			}
		}
	}
}