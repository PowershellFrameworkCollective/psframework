#region Logging Execution
# Action that is performed at the beginning of each logging cycle
$start_event = {
	$script:paramSendPsgelfTcp = @{
		'GelfServer' = Get-ConfigValue -Name 'GelfServer'
		'Port'	     = Get-ConfigValue -Name 'Port'
		'Encrypt'    = Get-ConfigValue -Name 'Encrypt'
	}
}

# Action that is performed for each message item that is being logged
$message_Event = {
	param (
		$Message
	)
	
	$gelf_params = $script:paramSendPsgelfTcp.Clone()
	$gelf_params['ShortMessage'] = $Message.LogMessage
	$gelf_params['HostName'] = $Message.ComputerName
	$gelf_params['DateTime'] = $Message.Timestamp
	
	$gelf_params['Level'] = switch ($Message.Level)
	{
		'Critical' { 1 }
		'Important' { 1 }
		'Output' { 3 }
		'Host' { 4 }
		'Significant' { 5 }
		'VeryVerbose' { 6 }
		'Verbose' { 6 }
		'SomewhatVerbose' { 6 }
		'System' { 6 }
		
		default { 7 }
	}
	
	if ($Message.ErrorRecord)
	{
		$gelf_params['FullMessage'] = $Message.ErrorRecord | ConvertTo-Json
	}
	
	# build the additional fields
	$gelf_properties = $Message.PSObject.Properties | Where-Object {
		$_.Name -notin @('Message', 'LogMessage', 'ComputerName', 'Timestamp', 'Level', 'ErrorRecord')
	}
	
	$gelf_params['AdditionalField'] = @{ }
	foreach ($gelf_property in $gelf_properties)
	{
		$gelf_params['AdditionalField'][$gelf_property.Name] = $gelf_property.Value
	}
	
	PSGELF\Send-PSGelfTCP @gelf_params
}
#endregion Logging Execution

#region Installation
$installationParameters = {
	$results = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$attributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
	$parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
	$parameterAttribute.ParameterSetName = '__AllParameterSets'
	$attributesCollection.Add($parameterAttribute)
	
	$validateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute('CurrentUser', 'AllUsers')
	$attributesCollection.Add($validateSetAttribute)
	
	$runtimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter("Scope", [string], $attributesCollection)
	$results.Add("Scope", $runtimeParam)

	$attributesCollection2 = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
	$runtimeParam2 = New-Object System.Management.Automation.RuntimeDefinedParameter("Repository", [string], $attributesCollection2)
	$results.Add("Repository", $runtimeParam2)
	$results
}

$installation_script = {
	param (
		$BoundParameters
	)
	
	$paramInstallModule = @{
		Name = 'PSGELF'
	}
	if ($BoundParameters.Scope) { $paramInstallModule['Scope'] = $BoundParameters.Scope }
	elseif (-not (Test-PSFPowerShell -Elevated)) { $paramInstallModule['Scope'] = 'CurrentUser' }
	if ($BoundParameters.Repository) { $paramInstallModule['Repository'] = $BoundParameters.Repository }
	else { $paramInstallModule['Repository'] = Get-PSFConfigValue -FullName 'PSFramework.System.DefaultRepository' -Fallback 'PSGallery' }
	
	Install-Module @paramInstallModule
}

$isInstalled_script = {
	(Get-Module PSGELF -ListAvailable) -as [bool]
}
#endregion Installation

# Configuration settings to initialize
$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.GELF.GelfServer' -Value "" -Initialize -Validation string -Description "The GELF server to send logs to"
	Set-PSFConfig -Module PSFramework -Name 'Logging.GELF.Port' -Value "" -Initialize -Validation string -Description "The port number the GELF server listens on"
	Set-PSFConfig -Module PSFramework -Name 'Logging.GELF.Encrypt' -Value $true -Initialize -Validation bool -Description "Whether to use TLS encryption when communicating with the GELF server"
}

$paramRegisterPSFLoggingProvider = @{
	Name			   = "gelf"
	Version2		   = $true
	ConfigurationRoot  = 'PSFramework.Logging.GELF'
	InstanceProperties = 'GelfServer', 'Port', 'Encrypt'
	StartEvent		   = $start_event
	MessageEvent	   = $message_Event
	IsInstalledScript  = $isInstalled_script
	InstallationScript = $installation_script
	InstallationParameters = $installationParameters
	ConfigurationSettings = $configuration_Settings
	ConfigurationDefaultValues = @{
		Encrypt = $true
	}
}

Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider