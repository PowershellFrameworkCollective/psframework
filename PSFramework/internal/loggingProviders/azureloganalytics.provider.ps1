
$FunctionDefinitions = {
	function Export-DataToAzure {
		<#
        .SYNOPSIS
            Function to send logging data to an Azure Workspace

        .DESCRIPTION
            This function is the main function that takes a PSFMessage object to log in an Azure workspace via Rest API call.

        .PARAMETER Message
            This is a PSFMessage object that will be converted to serialized to Json injected to an Azure workspace

        .EXAMPLE
            Export-DataToAzure -Message $objectToProcess

        .NOTES
            # Adapted from https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-data-collector-api
            Rest API documentation: https://docs.microsoft.com/en-us/rest/api/azure/
            Azure Monitor HTTP Data Collector API: https://docs.microsoft.com/en-us/azure/azure-monitor/platform/data-collector-api#request-body

            Azure Monitor Data collection API Constrains
            --------------------------------------------
            1. Maximum of 30 MB per post to Azure Monitor Data Collector API. This is a size limit for a single post. If the data from a single post that exceeds 30 MB, you should split the data up to smaller sized chunks and send them concurrently.
            2. Maximum of 32 KB limit for field values. If the field value is greater than 32 KB, the data will be truncated.
            3. Recommended maximum number of fields for a given type is 50. This is a practical limit from a usability and search experience perspective.
            4. A table in a Log Analytics workspace only supports up to 500 columns (referred to as a field in this article).
            5. The maximum number of characters for the column name is 500.

            Notes on Azure workspace table
            ------------------------------
            The table in the Azure workspace will be the LogType specified in PSFConfig. The default is 'Message'
            When looking at the tables in the Azure workspace they will always have _CL appended to them. _CL stands for (for Custom Log)
            In the final table output in the Azure workspace each property imported to the table will have its own column
            and they will be specified by the property type that was inserted to the table.
            Each Azure workspace column name will be suffixed with the data type - _d for double, _b for boolean, _s for string, etc.

            How to register this provider
            -----------------------------
            Set-PSFLoggingProvider -Name AzureLogAnalytics -InstanceName YourInstanceName -WorkspaceId "AzureWorkspaceId" -SharedKey "AzureWorkspaceSharedKey" -LogType "Message" -enabled $True
        #>
		
		[cmdletbinding()]
		param (
			[parameter(Mandatory = $True)]
			$Message
		)
		
		begin {
			# Grab the default configuration values for the logging provider
			$WorkspaceID = Get-ConfigValue -Name 'WorkspaceId' | Resolve-Secret
			$SharedKey = Get-ConfigValue -Name 'SharedKey' | Resolve-Secret
			$LogType = Get-ConfigValue -Name 'LogType'
		}
		
		process {
			# Create a custom PSObject and convert it to a Json object using UTF8 encoding
			$loggingMessage = $Message | Microsoft.PowerShell.Utility\Select-Object $script:ala_headers
			
			$bodyAsJson = ConvertTo-Json $loggingMessage -Compress
			$body = [System.Text.Encoding]::UTF8.GetBytes($bodyAsJson)
			
			$restMethod = "POST"
			$restContentType = "application/json"
			$restResource = "/api/logs"
			$date = [DateTime]::UtcNow.ToString("r")
			$contentLength = $body.Length
			
			$signatureArgs = @{
				WorkspaceID     = $WorkspaceID
				SharedKey       = $SharedKey
				DateAndTime     = $date
				ContentLength   = $contentLength
				RestMethod      = $restMethod
				RestContentType = $restContentType
				RestResource    = $restResource
			}
			
			# Generate a signature needed to gain access to the Azure workspace
			$signature = Get-LogSignature @signatureArgs
			
			# RestAPI headers
			$headers = @{
				"Authorization"        = $signature
				"Log-Type"             = $logType
				"x-ms-date"            = $date
				"time-generated-field" = "TimeStamp"
			}
			
			try {
				$uri = "https://$($WorkspaceID).ods.opinsights.azure.com$($restResource)?api-version=2016-04-01"
				$webResponse = Invoke-WebRequest -Uri $uri -Method $restMethod -ContentType $restContentType -Headers $headers -Body $body -UseBasicParsing
				switch ($webResponse.StatusCode) {
					'400' {
						switch ($webResponse.StatusDescription) {
							'InactiveCustomer' { throw "Sucessful Post to Azure Workspace" }
							'InvalidApiVersion' { throw "The API version that you specified was not recognized by the service." }
							'InvalidCustomerId' { throw "The workspace ID specified is invalid." }
							'InvalidDataFormat' { throw "Invalid JSON was submitted. The response body might contain more information about how to resolve the error." }
							'InvalidLogType' { throw "The log type specified contained special characters or numerics." }
							'MissingApiVersion' { throw "The API version wasn't specified." }
							'MissingContentType' { throw "The content type wasn't specified." }
							'MissingLogType' { throw "The required value log type wasn't specified." }
							'UnsupportedContentType' { throw "The content type was not set to application/json." }
						}
					}
					
					'403' { throw "The service failed to authenticate the request. Verify that the workspace ID and connection key are valid." }
					'404' { throw "Either the URL provided is incorrect, or the request is too large." }
					'429' { throw "The service is experiencing a high volume of data from your account. Please retry the request later." }
					'500' { throw "The service encountered an internal error. Please retry the request." }
					'503' { throw "The service currently is unavailable to receive requests. Please retry your request." }
				}
			}
			catch { throw }
		}
	}
	
	function Get-LogSignature {
		<#
    .SYNOPSIS
        Function for computing a signature to connect to the Azure workspace

    .DESCRIPTION
        This function will compute a signature that will be used to connect to the Azure workspace in order to save logging data.

    .PARAMETER WorkspaceID
        WorkspaceID is the unique identifer for the Log Analytics workspace, and Signature is a Hash-based Message Authentication Code (HMAC) constructed from the request and computed by using the SHA256 algorithm, and then encoded using Base64 encoding.

    .PARAMETER SharedKey
        This is the Azure workspace shared key.

    .PARAMETER DateAndTime
        The name of a field in the data that contains the timestamp of the data item. If you specify a field then its contents are used for TimeGenerated. If this field isn't specified, the default for TimeGenerated is the time that the message is ingested. The contents of the message field should follow the ISO 8601 format YYYY-MM-DDThh:mm:ssZ.

    .PARAMETER ContentLength
        The content length of the object being injected to the Azure workspace table

    .PARAMETER RestMethod
        Rest Method being used in the connection.

    .PARAMETER RestContentType
        Rest content type being used in the connection.

    .PARAMETER RestResource
        The API resource name: /api/logs.

    .EXAMPLE
        Get-LogSignature @inParameters

    .NOTES
        Any request to the Log analytics HTTP Data Collector API must include the Authorization header.
        To authenticate a request, you must sign the request with either the primary or secondary key for the workspace that is making the request and pass that signature as part of the request.
    #>
		
		[cmdletbinding()]
		param (
			$WorkspaceID,
			
			$SharedKey,
			
			$DateAndTime,
			
			$ContentLength,
			
			$RestMethod,
			
			$RestContentType,
			
			$RestResource
		)
		
		process {
			$xHeaders = "x-ms-date:" + $DateAndTime
			$stringToHash = $RestMethod + "`n" + $ContentLength + "`n" + $RestContentType + "`n" + $xHeaders + "`n" + $RestResource
			$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
			$keyBytes = [Convert]::FromBase64String($sharedKey)
			$sha256 = New-Object System.Security.Cryptography.HMACSHA256
			$sha256.Key = $keyBytes
			$computedHash = $sha256.ComputeHash($bytesToHash)
			$encodedHash = [Convert]::ToBase64String($computedHash)
			$authorization = 'SharedKey {0}:{1}' -f $WorkspaceID, $encodedHash
			return $authorization
		}
	}
	
	function Resolve-Secret {
		[CmdletBinding()]
		param (
			[Parameter(ValueFromPipeline = $true)]
			$Secret
		)
		process {
			if ($Secret -is [string]) {
				return $Secret
			}
			if ($Secret -is [securestring]) {
				$cred = New-Object PSCredential('whatever', $Secret)
				return $cred.GetNetworkCredential().Password
			}
			if ($Secret -is [pscredential]) {
				$Secret.GetNetworkCredential().Password
			}
		}
	}
}

#region Events
$start_event = {
	$script:ala_headers = Get-ConfigValue -Name 'Headers' | ForEach-Object {
		switch ($_) {
			'Message' {
				@{
					Name       = 'Message'
					Expression = { $_.LogMessage }
				}
			}
			'Timestamp' {
				@{
					Name       = 'Timestamp'
					Expression = {
						if (-not (Get-ConfigValue -Name 'TimeFormat')) { $_.Timestamp.ToUniversalTime() }
						else { $_.Timestamp.ToUniversalTime().ToString((Get-ConfigValue -Name 'TimeFormat')) }
					}
				}
			}
			'Level' {
				@{
					Name       = 'Level'
					Expression = { $_.Level -as [string] }
				}
			}
			default { $_ }
		}
	}
}
$message_event = {
	param (
		$Message
	)
	
	Export-DataToAzure -Message $Message
}
#endregion Events

# Configuration values for the logging provider
$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalytics.WorkspaceId' -Value "" -Initialize -Validation 'secret' -Description "WorkspaceId for the Azure Workspace we are logging our data objects to."
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalytics.SharedKey' -Value "" -Initialize -Validation 'secret' -Description "SharedId for the Azure Workspace we are logging our data objects to."
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalytics.LogType' -Value "Message" -Initialize -Validation 'string' -Description "Log type we will log information to."
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalytics.TimeFormat' -Value "" -Initialize -Validation 'string' -Description "Format timestamps will be written with."
	Set-PSFConfig -Module PSFramework -Name 'Logging.AzureLogAnalytics.Headers' -Value 'Message', 'Timestamp', 'Level', 'Tags', 'Data', 'ComputerName', 'Runspace', 'UserName', 'ModuleName', 'FunctionName', 'File', 'CallStack', 'TargetObject', 'ErrorRecord' -Initialize -Validation 'stringarray' -Description "The properties of the message to log."
}

# Registered parameters for the logging provider.
# ConfigurationDefaultValues are used for all instances of the azure logging provider
$paramRegisterPSFAzureLogAnalyticsProvider = @{
	Name                       = "AzureLogAnalytics"
	Version2                   = $true
	ConfigurationRoot          = 'PSFramework.Logging.AzureLogAnalytics'
	InstanceProperties         = 'WorkspaceId', 'SharedKey', 'LogType', 'TimeFormat', 'Headers'
	StartEvent                 = $start_event
	MessageEvent               = $message_Event
	ConfigurationSettings      = $configuration_Settings
	FunctionDefinitions        = $functionDefinitions
	ConfigurationDefaultValues = @{
		LogType = 'Message'
		Headers = 'Message', 'Timestamp', 'Level', 'Tags', 'Data', 'ComputerName', 'Runspace', 'UserName', 'ModuleName', 'FunctionName', 'File', 'CallStack', 'TargetObject', 'ErrorRecord'
	}
}

# Register the Azure logging provider
Register-PSFLoggingProvider @paramRegisterPSFAzureLogAnalyticsProvider