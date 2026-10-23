#region Functions
$functionDefinitions = {
	function Update-LAToken {
		[CmdletBinding()]
		param ()

		trap {
			[PSFramework.PSFCore.PSFCoreHost]::WriteDebug('Error Getting Tokens', @{ Config = $config; Error = $_; Param = $param; ActualParam = $actualParam })
			throw $_
		}

		$param = @{}
		$eaParam = 'ClientID', 'TenantID', 'Scopes', 'Browser', 'RedirectUri', 'RefreshToken', 'RefreshTokenObject', 'Certificate', 'CertificateThumbprint', 'CertificateName', 'CertificatePath', 'CertificatePassword', 'ClientSecret', 'Credential', 'VaultName', 'SecretName', 'Identity', 'IdentityID', 'IdentityType', 'FallBackAzAccount', 'AsAzAccount', 'ShowDialog', 'Federated', 'FederationProvider', 'Assertion', 'Environment', 'AuthenticationUrl', 'AzureToken', 'MonitorToken'
		$config = Select-PSFConfig -FullName "$($script:configRoot).*"| Where-Object _FullName -eq $script:configRoot
		foreach ($paramName in $eaParam) {
			if ($config.$paramName -notin $null, '', @()) {
				$param.$paramName = $config.$paramName
			}
		}

		$isEqual = [PSFramework.Utility.UtilityHost]::ComparePS(
			$param,
			$script:eaConfig,
			$false, # CaseSensitive
			$false, # Recursive
			$false # Monodirectional
		)
		if ($isEqual) { return }

		[PSFramework.PSFCore.PSFCoreHost]::WriteDebug('Recalculating Tokens', @{ New = $param; Old = $script:eaConfig })

		$actualParam = $param.Clone()
		# Cleanup to make sure they are not passed through, but used to determine whether a reconnect should be done (above).
		$actualParam.Remove('AzureToken')
		$actualParam.Remove('MonitorToken')

		$paramCount = $actualParam.Count

		if (-not $actualParam.ClientID -and -not (Test-PSFParameterSet -Command $script:eaConnectCmd -Parameters $actualParam.Keys -Sets 'RefreshObject', 'Identity', 'AzAccount')) { $actualParam.ClientID = 'Azure' }
		if ($actualParam.CertificatePassword -and $actualParam.CertificatePassword -is [string]) { $actualParam.CertificatePassword = $actualParam.CertificatePassword | ConvertTo-SecureString -AsPlainText -Force }
		if ($actualParam.CertificatePassword -and $actualParam.CertificatePassword -is [PSCredential]) { $actualParam.CertificatePassword = $actualParam.CertificatePassword.Password }
		if ($actualParam.ClientSecret -and $actualParam.ClientSecret -is [string]) { $actualParam.ClientSecret = $actualParam.ClientSecret | ConvertTo-SecureString -AsPlainText -Force }
		if ($actualParam.ClientSecret -and $actualParam.ClientSecret -is [PSCredential]) { $actualParam.ClientSecret = $actualParam.ClientSecret.Password }

		$token = $null
		$script:eaToken = $null

		if ($config.AzureToken) {
			if ('Azure' -ne $config.AzureToken.Service) { Write-Error -Message "Invalid Azure Token | Expected Service: Azure | Received Service: $($config.AzureToken.Service)" -TargetObject $config.AzureToken -ErrorAction Stop }

			try { Import-EntraToken -Token $config.AzureToken -NoRenew -ErrorAction Stop }
			catch { Write-Error -Message "Failed to import Azure Token: $_" -TargetObject $config.AzureToken -ErrorAction Stop }

			$azureToken = Get-EntraToken -Service Azure

			# The bare minimum needed to reuse a RefreshToken, or reuse a Certificate/ClientSecret from the Azure token
			if ($paramCount -lt 1) { $actualParam.ClientID = $azureToken.ClientID }
			if ($paramCount -lt 1) { $actualParam.TenantID = $azureToken.TenantID }

			<#
			In case we only specify an Azure token and not a Monitor token.
			
			- Delegate flows use the refresh token
			- Identity flows have no need to specify a token to begin with
			#>
			if ($azureToken.Certificate -and $paramCount -lt 1) { $actualParam.Certificate = $azureToken.Certificate }
			if ($azureToken.ClientSecret -and $paramCount -lt 1) { $actualParam.ClientSecret = $azureToken.ClientSecret }
		}
		else {
			try { Connect-EntraService @actualParam -Service Azure -ErrorAction Stop }
			catch { throw }
		}

		if (Test-PSFParameterSet -Command $script:eaConnectCmd -Parameters $actualParam.Keys -Sets 'Browser', 'DeviceCode') {
			$actualParam.UseRefreshToken = $true
		}

		if ($config.MonitorToken) {
			try { $token = Import-EntraToken -Token $config.MonitorToken -NoRenew -PassThru -ErrorAction Stop }
			catch { Write-Error -Message "Failed to import Azure Monitor Token: $_" -TargetObject $config.MonitorToken -ErrorAction Stop }
		}
		else {
			try { $token = Connect-EntraService @actualParam -Resource 'https://monitor.azure.com/' -ErrorAction Stop }
			catch { throw }
		}

		if ($token) {
			$script:eaToken = $token
			$script:eaConfig = $param
		}
	}

	function Update-LAWorkspacePath {
		[CmdletBinding()]
		param ()

		$param = @{
			Subscription  = Get-ConfigValue -Name Subscription
			ResourceGroup = Get-ConfigValue -Name ResourceGroup
			Stream        = Get-ConfigValue -Name Stream
			DcrName       = Get-ConfigValue -Name DcrName
			DceName       = Get-ConfigValue -Name DceName
			Table         = Get-ConfigValue -Name Table
		}

		$isEqual = [PSFramework.Utility.UtilityHost]::ComparePS(
			$param, # Table1
			$script:laConfig, # Table2
			$false, # CaseSensitive
			$false, # Recursive
			$false # Monodirectional
		)
		if ($isEqual) { return }

		if (-not $param.DcrName) { throw 'No Data Collection Rule (DcrName) specified!' }
		if (-not $param.DceName) { throw 'No Data Collection Endpoint (DceName) specified!' }

		[PSFramework.PSFCore.PSFCoreHost]::WriteDebug('Recalculating LA Request Path', @{ New = $param; Old = $script:laConfig })
		
		$script:laConfig = @{}
		$script:laPath = ''

		try {
			$dceObject = Invoke-EntraRequest -Service Azure -Path "subscriptions/$($param.Subscription)/resourceGroups/$($param.ResourceGroup)/providers/Microsoft.Insights/dataCollectionEndpoints/$($param.DceName)" -Query @{
				'api-version' = '2024-03-11'
			}
		}
		catch { throw "Failed to resolve Data Collection Endpoint $($param.DceName): $_`nPath: subscriptions/$($param.Subscription)/resourceGroups/$($param.ResourceGroup)/providers/Microsoft.Insights/dataCollectionEndpoints/$($param.DceName)" }

		try {
			$dcrObject = Invoke-EntraRequest -Service Azure -Path "subscriptions/$($param.Subscription)/resourceGroups/$($param.ResourceGroup)/providers/Microsoft.Insights/dataCollectionRules/$($param.DcrName)" -Query @{
				'api-version' = '2024-03-11'
			}
		}
		catch { throw "Failed to resolve Data Collection Rule $($param.DcrName): $_`nPath: subscriptions/$($param.Subscription)/resourceGroups/$($param.ResourceGroup)/providers/Microsoft.Insights/dataCollectionRules/$($param.DcrName)" }

		$streamName = $null
		if ($param.Stream) { $streamName = $param.Stream }
		else {
			$streams = $dcrObject.properties.dataFlows.streams | Sort-Object -Unique
			if (@($streams).Count -eq 1) {
				$streamName = $($streams)
			}
			elseif ($param.Table -and @($streams | Where-Object { $_ -match $param.Table }).Count -eq 1) {
				$streamName = $streams | Where-Object { $_ -match $param.Table }
			}
		}

		if (-not $streamName) { throw "Unable to resolve stream for $($param.Table) in $($param.DcrName)" }

		$script:laConfig = $param

		$script:laPath = "$($dceObject.properties.logsIngestion.endpoint)/dataCollectionRules/$($dcrObject.properties.ImmutableId)/streams/$streamName"
	}

	function Write-LAMessage {
		[CmdletBinding()]
		param (
			[PSFramework.Message.LogEntry]
			$Message,

			[int]
			$BatchSize,

			[System.Collections.ArrayList]
			$Messages,

			[switch]
			$Flush
		)

		# If we failed to calculate the path to push log analytics data, no point in attempting to do so
		# The failed Start phase handles the error logging, no point flooding it with extra-messages to muddle the water.
		if (-not $script:laPath) {
			return
		}

		if ($null -ne $Message) { $null = $Messages.Add($Message) }
		if (-not $Flush -and $Messages.Count -lt $BatchSize) {
			return
		}
		if ($Flush -and $Messages.Count -lt 1) { return }

		$payload = $Messages | Select-PSFObject -Property $script:laHeaders
		$script:lastPayload = $payload
		$payloadJson = ConvertTo-Json -InputObject @($payload) -Compress -Depth 3
		$Messages.Clear()
		Invoke-EntraRequest -Method Post -Path $script:laPath -Token $script:eaToken -Query @{
			'api-version' = '2023-01-01'
		} -ContentType 'application/json' -Body $payloadJson -Header @{ charset = 'utf-8' }
	}
}
#endregion Functions
#region Main Events
$begin_event = {
	$modulePath = Join-Path -Path ([PSFramework.PSFCore.PSFCoreHost]::ModuleRoot) -ChildPath 'modules/EntraAuth/*/EntraAuth.psd1'
	Import-Module -Name (Get-Item -Path $modulePath).FullName -ErrorAction Stop

	$script:configRoot = $script:Instance.ConfigurationRoot
	if ($script:Instance.Name -and $script:Instance.Name -ne 'Default') {
		$script:configRoot += ".$($script:Instance.Name)"
	}

	$script:eaToken = $null
	$script:eaConfig = @{}
	$script:laConfig = @{}
	$script:laPath = ''
	$script:laHeaders = @()
	$script:laLastHeaders = @()
	$script:eaConnectCmd = Get-Command Connect-EntraService
}
$start_event = {
	trap {
		throw $_
	}
	$script:messages = [System.Collections.ArrayList]@()
	$script:batchsize = Get-ConfigValue -Name BatchSize
	if (-not $script:batchsize -or $script:batchsize -lt 1) {
		$script:batchsize = 25
	}
	$newHeaders = Get-ConfigValue -Name Headers
	if (-not [System.Management.Automation.LanguagePrimitives]::Equals($newHeaders, $script:laLastHeaders)) {
		[PSFramework.PSFCore.PSFCoreHost]::WriteDebug('Recalculating Headers', @{ New = $newHeaders; Old = $script:laLastHeaders })
		$script:laHeaders = $newHeaders | ForEach-Object {
			if ($_ -is [hashtable]) { return $_ }

			if (
				$_ -notmatch '^[a-zA-Z\d]+$' -and
				$_ -notmatch '^[a-zA-Z\d]+ as [a-zA-Z\d]+$' -and
				$_ -notmatch '^[a-zA-Z\d]+ as [a-zA-Z\d]+ to (string|int)$'
			) { throw "Unsupported Header format: $_ | Cannot use special letters, access subproperties or invoke methods or typeconvert to anything other than string or int" }

			switch -regex ($_) {
				'^Message$' { $_ -replace 'Message', 'LogMessage as Message'; break }
				'^Message' { $_ -replace '^Message', 'LogMessage' }
				'^Timestamp$' { 'Timestamp.ToUniversalTime().ToString("o") as Timestamp' }
				'^Level$' { 'Level to String' }
				'^Callstack$' { 'Callstack to String' }
				default { $_ }
			}
		}
		$script:laLastHeaders = $newHeaders
	}

	Update-LAToken -ErrorAction Stop
	Update-LAWorkspacePath
}
$message_event = {
	param (
		$Message
	)

	Write-LAMessage -Message $Message -BatchSize $script:batchsize -Messages $script:messages
}
$end_event = {
	Write-LAMessage -Flush -Messages $script:messages
}
#endregion Main Events

# Configuration values for the logging provider
$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Subscription' -Value '' -Initialize -Validation string -Description 'Mandatory. The Subscription (by its ID, not name) the Data Collection Endpoint & Rule are in. Both must be in the same Resource Group.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.ResourceGroup' -Value '' -Initialize -Validation string -Description 'Mandatory. The resource Group the Data Collection Endpoint & Rule are in. Both must be in the same Resource Group.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.DceName' -Value '' -Initialize -Validation string -Description 'Mandatory. Name of the Data Collection Endpoint determining the request url used.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.DcrName' -Value '' -Initialize -Validation string -Description 'Mandatory. Name of the Data Collection Rule to send data to.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Stream' -Value '' -Initialize -Validation string -Description 'The specific name of the Data Stream on the Data Collection Rule to send data to. Overrides Automatic Stream selection or selection by Table name.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Table' -Value '' -Initialize -Validation string -Description 'The name of the table in Azure Log Analytics. Optional, used as tie breaker if the Data Collection Rule has multiple dataflows / streams to select from. By default, if the DCR only has one Data Flow configured, this can be omitted.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Headers' -Value 'Message', 'Timestamp', 'Level', 'Tags', 'Data', 'ComputerName', 'Runspace', 'UserName', 'ModuleName', 'FunctionName', 'File', 'Line', 'CallStack', 'TargetObject', 'ErrorRecord' -Initialize -Validation stringarray -Description 'The properties on the messages to push to Log Analytics table. Supports renaming by specifying properties like this: "Timestamp as Time"'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.BatchSize' -Value 25 -Initialize -Validation integerpositive -Description 'Up to how many messages are uploaded in one request. Larger improves throughput but may lead to lost requests when sending too much data.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.ClientID' -Value $null -Initialize -Validation string -Description 'Authentication Info. The Client ID of the Application to use for authentication. Defaults to the same application used for Connect-AzAccount.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.TenantID' -Value $null -Initialize -Validation string -Description 'Authentication Info. The Tenant ID of the Application to use for authentication. Defaults to the tenant of the user if in delegate mode, must be specified in Application mode, other than for MSI authentication.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Browser' -Value $null -Initialize -Validation bool -Description 'Authentication Info. Explicitly authenticate in Delegate Authorization Code flow - will use the default browser to have you log in as yourself.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.RedirectUri' -Value $null -Initialize -Validation string -Description 'Authentication Info. Override the automatic redirect to localhost in Authorization Code flow. Usually needs not be adjusted.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.RefreshToken' -Value $null -Initialize -Validation string -Description 'Authentication Info. A refresh token (as string) to use for authenticating by reusing an existing token.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.RefreshTokenObject' -Value $null -Initialize -Description 'Authentication Info. A resfresh token (as EntraAuth token object) to use for authenticating by reusing an existing token.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Certificate' -Value $null -Initialize -Description 'Authentication Info. A certificate (as X509Certificate2 object) to use for authenticating in application mode.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.CertificateThumbprint' -Value $null -Initialize -Validation string -Description 'Authentication Info. A certificate (selected by its thumbprint from your windows certificate stores) to use for authenticating in application mode.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.CertificateName' -Value $null -Initialize -Validation string -Description 'Authentication Info. A certificate (selected by its CN from your windows certificate stores) to use for authenticating in application mode.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.CertificatePath' -Value $null -Initialize -Validation string -Description 'Authentication Info. Path to .pfx file containing the certificate to use for authenticating in application mode. Use together with CertificatePassword'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.CertificatePassword' -Value $null -Initialize -Validation secret -Description 'Authentication Info. Password to the .pfx file containing the certificate to use for authenticating in application mode. Use together with CertificatePath'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.ClientSecret' -Value $null -Initialize -Validation secret -Description 'Authentication Info. The clientsecret to use for authenticating in application mode.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Identity' -Value $null -Initialize -Validation bool -Description 'Authentication Info. Authenticate as the Managed Identity - System-Managed or User-Assigned. Will default to System-Managed unloss also specifying an IdentityID'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.IdentityID' -Value $null -Initialize -Validation string -Description 'Authentication Info. Id of the System-Assigned identity to use. Use together with IdentityType to determine whether it is a ClientID, PrincipalID or ResourceID.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.IdentityType' -Value $null -Initialize -Validation string -Description 'Authentication Info. Use together with IdentityID to specify whether the user-assigned identity is a ClientID, PrincipalID or ResourceID.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.FallBackAzAccount' -Value $null -Initialize -Validation bool -Description 'Authentication Info. Fallback to using the currently established AzContext from Connect-AzAccount. Intended for use with Identity & Federated flows as a local fallback when testing on your own machine.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.AsAzAccount' -Value $null -Initialize -Validation bool -Description 'Authentication Info. Reuse the connection established with Connect-AzAccount. Requires the connection having previously established.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.ShowDialog' -Value $null -Initialize -Validation string -Description 'Authentication Info. When using the AzAccount session, should the interactive UI be shown? "auto": Only when needed. "always": Show no matter what. "never": Don''t show, but will error the logging if required.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Federated' -Value $null -Initialize -Validation bool -Description 'Authentication Info. Use Federated credentials to authenticate. Use when running on a system supporting Managed Identities but your organization requires the use of an App Registration & Enterprise Application.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.FederationProvider' -Value $null -Initialize -Validation string -Description 'Authentication Info. Which Federation Provider to use. Overrides the default autodetection.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Assertion' -Value $null -Initialize -Validation string -Description 'Authentication Info. The credentials from the federated identity provider to use in an Federated Credentials authentication flow. Highly optional.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.Environment' -Value $null -Initialize -Validation string -Description 'Authentication Info. What environment the tenant runs in. Defaults to "Global", options: Global, USGov, USGovDOD, China.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.AuthenticationUrl' -Value $null -Initialize -Validation string -Description 'Authentication Info. The url used for the authentication requests to retrieve tokens. Generally provided by the Environment parameter, but can be overridden in case of need.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.AzureToken' -Value $null -Initialize -Description 'Authentication Info. A previously established token using Connect-EntraService to the "Azure" service, NOT a plain access token string.'
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalyticsV2.MonitorToken' -Value $null -Initialize -Description 'Authentication Info. A previously established token using Connect-EntraService to the "https://monitor.azure.com/" resource (or environment-specific alternatives), NOT a plain access token string.'
}

# Registered parameters for the logging provider.
# ConfigurationDefaultValues are used for all instances of the azure logging provider
$paramRegisterPSFAzureLogAnalyticsProvider = @{
	Name                       = 'AzureLogAnalyticsV2'
	Version2                   = $true
	Description                = 'Logs to Azure Log Analytics through the Logs Ingestion API'
	ConfigurationRoot          = 'PSFramework.Logging.AzureLogAnalyticsV2'
	InstanceProperties         = 'Subscription', 'ResourceGroup', 'DceName', 'DcrName', 'Stream', 'Table', 'Headers', 'BatchSize', 'ClientID', 'TenantID', 'Browser', 'RedirectUri', 'RefreshToken', 'RefreshTokenObject', 'Certificate', 'CertificateThumbprint', 'CertificateName', 'CertificatePath', 'CertificatePassword', 'ClientSecret', 'Identity', 'IdentityID', 'IdentityType', 'FallBackAzAccount', 'AsAzAccount', 'ShowDialog', 'Federated', 'FederationProvider', 'Assertion', 'Environment', 'AuthenticationUrl', 'AzureToken', 'MonitorToken'
	BeginEvent                 = $begin_event
	StartEvent                 = $start_event
	MessageEvent               = $message_Event
	EndEvent                   = $end_event
	ConfigurationSettings      = $configuration_Settings
	FunctionDefinitions        = $functionDefinitions
	ConfigurationDefaultValues = @{
		Headers   = 'Message', 'Timestamp', 'Level', 'Tags', 'Data', 'ComputerName', 'Runspace', 'UserName', 'ModuleName', 'FunctionName', 'File', 'Line', 'CallStack', 'TargetObject', 'ErrorRecord'
		BatchSize = 25
	}
}

# Register the Azure logging provider
Register-PSFLoggingProvider @paramRegisterPSFAzureLogAnalyticsProvider