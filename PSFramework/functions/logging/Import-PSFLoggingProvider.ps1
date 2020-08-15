function Import-PSFLoggingProvider
{
<#
	.SYNOPSIS
		Imports logging provider code and configuration from a hosting source.
	
	.DESCRIPTION
		Imports logging provider code and configuration from a hosting source.
		This enables centrally providing logging provider settings that are retrieved by running this command.
	
		You can simply run this command with no arguments.
		It will then only do anything, if there is a defined value for the configuration setting "PSFramework.Logging.Provider.Source".
	
		If specifying a path or relying on the configuration setting above, it expects the path to ...
		- Be either a weblink or a file system path
		- Point at a json file containing the relevant provider information
		- Be accessible without specific authentication information
	
		Alternatively to specifying a path (or relying on the configured value), you can also give it the same data raw via the "-Data" parameter.
		This needs to be the exact same data layout as provided by the json file, only already readied as PowerShell objects.
	
		In both cases, you provide one or multiple items which may contain the following Properties (all others will be ignored):
		- ProviderPath
		- ProviderName
		- InstallationConfig
		- ProviderConfig
	
		# Providerpath
		#---------------
	
		The ProviderPath property is a full or relative path to a scriptfile that contains LoggingProvider code.
		A relative path would be relative to the path of the json file originally retrieved.
		If calling this command with the "-Data" parameter, relative paths are not supported.
		The scriptfile must be valid PowerShell code, however the original extension matters not.
		The file will be run as untrusted code, so it will fail in Constraiend Language Mode, unless you sign the provider script with a whitelisted publisher certificate.
	
		# ProviderName
		#---------------
	
		The name of the provider to install/configure.
		This property is needed in order to use the subsequent two configuration properties.
		
		Note: If specifying both ProviderPath and ProviderName, it will FIRST install the new provider.
		You can thus deploy and configure a provider in the same setting.
	
		# InstallationConfig
		#---------------------
	
		A PSObject with properties of its own.
		These properties should contain the property & values you would use in Install-PSFLoggingProvider.
		Invalid entries (property-names that do not match a parameter on Install-PSFLoggingProvider) in this call will cause an error loading the setting.
	
		# ProviderConfig
		#-----------------
		
		A PSObject with properties of its own.
		Or an array thereof, if you want to configure multiple instances of the same provider in one go.
		Similar to the InstallationConfig property, these property/value pairs are used to dynamically bind to Set-PSFLoggingProvider, configuring the provider.
	
	
		Example json file:
		[
			{
				"ProviderName":  "logfile",
				"ProviderConfig":  {
					"InstanceName":  "SystemLogInstance",
					"FilePath":  "C:\\logs\\MyTask-%date%.csv",
					"TimeFormat":  "yyyy-MM-dd HH:mm:ss.fff",
					"Enabled":  true
				}
			}
		]
	
	.PARAMETER Path
		Path to a json file providing logging provider settings or new logging providers to load.
		Can be either a weblink or a file system path.
		See description for details on how the json file should look like.
	
	.PARAMETER Data
		The finished provider data to process.
		The PowerShell object version of the json data otherwise provided through a path.
		See description for details on how the data should look like.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Import-PSFLoggingProvider
	
		Imports the preconfigured logging provider resource file (or silently does nothing if none is configured).
	
	.EXAMPLE
		PS C:\> Import-PSFLoggingProvider -Path \\server\share\psframework\logging.json
	
		Imports the logging provider resource file from the specified network path.
#>
	[CmdletBinding(DefaultParameterSetName = 'Path')]
	param (
		[Parameter(ParameterSetName = 'Path')]
		[PsfValidateScript('PSFramework.Validate.Uri.Absolute', ErrorString = 'PSFramework.Validate.Uri.Absolute')]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Data')]
		$Data,
		
		[switch]
		$EnableException
	)
	
	begin
	{
		#region Helper Functions
		function Import-ProviderData
		{
			[CmdletBinding()]
			param (
				$Data,
				
				[AllowEmptyString()]
				[string]
				$ConfigPath
			)
			
			if ($Data.ProviderPath)
			{
				try { Install-ProviderFile -Path $Data.ProviderPath -ConfigPath $ConfigPath }
				catch { throw }
			}
			
			if ($Data.ProviderName)
			{
				if ($Data.InstallationConfig)
				{
					$config = $Data.InstallationConfig | ConvertTo-PSFHashtable
					Install-PSFLoggingProvider -Name $Data.ProviderName @config
				}
				foreach ($instance in $Data.ProviderConfig)
				{
					$config = $instance | ConvertTo-PSFHashtable
					Set-PSFLoggingProvider -Name $Data.ProviderName @config
				}
			}
		}
		
		function Install-ProviderFile
		{
			[CmdletBinding()]
			param (
				[string]
				$Path,
				
				[AllowEmptyString()]
				[string]
				$ConfigPath
			)
			
			#region Resolve Path and get code data
			$basePath = ""
			if ($ConfigPath) { $basePath = $ConfigPath -replace '[\\/][^\\/]+$' }
			
			[uri]$uri = $Path
			if (-not $uri.IsAbsoluteUri -and $ConfigPath)
			{
				switch (([uri]$basePath).Scheme)
				{
					'https' { $uri = '{0}/{1}' -f $basePath, $Path }
					'file' { $uri = '{0}{1}{2}' -f $basePath, [System.IO.Path]::DirectorySeparatorChar, $Path }
				}
			}
			if (-not $uri.IsAbsoluteUri) { throw "Invalid path: $Path - Cannot resolve absolute path!" }
			
			try
			{
				if ($uri.Scheme -eq 'file') { [string]$dataReceived = Get-Content -Path $uri -ErrorAction Stop -Raw }
				else { [string]$dataReceived = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction Stop }
			}
			catch { throw }
			#endregion Resolve Path and get code data
			
			#region Execute provider scriptcode
			$errors = $null
			$null = [System.Management.Automation.Language.Parser]::ParseInput($dataReceived, [ref]$null, [ref]$errors)
			if ($errors) { throw "Syntax error in file processed from $uri" }
			
			$tempPath = Get-PSFPath -Name Temp
			$scriptPath = Join-Path -Path $tempPath -ChildPath "provider-$(Get-Random).ps1"
			$encoding = New-Object System.Text.UTF8Encoding($true)
			[System.IO.File]::WriteAllText($scriptPath, $dataReceived, $encoding)
			
			# Loading a file from within the module context runs the provider script from within that (trusted) context as well.
			# This has various nasty consequences in Constrained language Mode
			# We avoid this by rehoming the scriptblock to the global sessionstate
			$scriptBlock = { & $args[0] }
			[PSFramework.Utility.UtilityHost]::ImportScriptBlock($scriptBlock, $true) # $true = Import into global, rather than local sessionstate
			try { $scriptBlock.Invoke($scriptPath) }
			catch { throw }
			Remove-Item -Path $scriptPath -Force -ErrorAction Ignore
			#endregion Execute provider scriptcode
		}
		#endregion Helper Functions
	}
	process
	{
		$effectivePath = ""
		switch ($PSCmdlet.ParameterSetName)
		{
			#region Process path-based imports
			'Path'
			{
				$effectivePath = $Path
				if (-not $effectivePath) { $effectivePath = Get-PSFConfigValue -FullName 'PSFramework.Logging.Provider.Source' }
				
				# This case is relevant when adding the command "just in case", where in some environments the configuration may be provided and in others not.
				if (-not $effectivePath) { return }
				
				[uri]$uri = $effectivePath
				try
				{
					if ($uri.Scheme -eq 'file') { $dataReceived = Get-Content -Path $effectivePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
					else { $dataReceived = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
				}
				catch
				{
					Stop-PSFFunction -String 'Import-PSFLoggingProvider.Import.Error' -StringValues $effectivePath -ErrorRecord $_ -EnableException $EnableException
					return
				}
			}
			#endregion Process path-based imports
			#region Process offered data
			'Data'
			{
				$dataReceived = $Data
			}
			#endregion Process offered data
		}
		foreach ($datum in $dataReceived)
		{
			try { Import-ProviderData -Data $datum }
			catch { Stop-PSFFunction -String 'Import-PSFLoggingProvider.Datum.Error' -EnableException $EnableException -ErrorRecord $_ -Continue -Target $datum }
		}
	}
}