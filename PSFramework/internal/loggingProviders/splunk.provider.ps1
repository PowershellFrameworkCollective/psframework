$functionDefinitions = {
	function Send-SplunkData
	{
<#
	.SYNOPSIS
		Writes data to a splunk http event collector.
	
	.DESCRIPTION
		Writes data to a splunk http event collector.
		See this blog post for setting up the Splunk server:
		https://ntsystems.it/post/sending-events-to-splunks-http-event-collector-with-powershell
	
	.PARAMETER InputObject
		The object to send as message.
	
	.PARAMETER HostName
		The name of the computer from which the message was generated.
	
	.PARAMETER Timestamp
		The timestamp fron when the message was generated.
	
	.PARAMETER Uri
		Link to the http collector endpoint to which to write to.
		Example: https://localhost:8088/services/collector
	
	.PARAMETER Token
		The token associated with the http event collector.
#>
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			$InputObject,
			
			[Parameter(Mandatory = $true)]
			[string]
			$HostName,
			
			[Parameter(Mandatory = $true)]
			[System.DateTime]
			$Timestamp,
			
			[Parameter(Mandatory = $true)]
			[string]
			$Uri,
			
			[Parameter(Mandatory = $true)]
			[string]
			$Token
		)
		process
		{
			# Splunk events can have a 'time' property in epoch time. If it's not set, use current system time.
			$unixEpochStart = New-Object -TypeName DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, ([DateTimeKind]::Utc)
			$unixEpochTime = [int]($Timestamp.ToUniversalTime() - $unixEpochStart).TotalSeconds
			
			# Create json object to send
			$eventData = @{
				event = $InputObject
				host  = $HostName
				time = $unixEpochTime
			}
			if ($index = Get-ConfigValue -Name Index) { $eventData.index = $index }
			if ($source = Get-ConfigValue -Name Source) { $eventData.source = $source }
			if ($sourcetype = Get-ConfigValue -Name SourceType) { $eventData.sourcetype = $sourcetype }
			
			$body = ConvertTo-Json -InputObject $eventData -Compress
			
			# Only return if something went wrong, i.e. http response is not "success"
			try { $null = Invoke-RestMethodCustom -Uri $uri -Method Post -Headers @{ Authorization = "Splunk $Token" } -Body $body -ErrorAction Stop -IgnoreCert:$(Get-ConfigValue -Name IgnoreCert) }
			catch { throw }
		}
	}
	
	function Invoke-RestMethodCustom
	{
		[CmdletBinding()]
		param (
			[string]
			$Uri,
			
			[System.Collections.Hashtable]
			$Headers,
			
			[string]
			$Method,
			
			[string]
			$ContentType = 'application/json',
			
			[string]
			$Body,
			
			[switch]
			$IgnoreCert
		)
		
		process
		{
			$request = [System.Net.WebRequest]::Create($Uri)
			foreach ($key in $Headers.Keys) { $request.Headers[$key] = $Headers[$key] }
			$request.Method = $Method
			if ($IgnoreCert) { $request.ServerCertificateValidationCallback = { $true } }
			$request.ContentLength = $Body.Length
			
			$requestWriter = New-Object System.IO.StreamWriter($request.GetRequestStream(), [System.Text.Encoding]::ASCII)
			$requestWriter.Write($Body)
			$requestWriter.Close()
			
			try
			{
				$responseStream = $request.GetResponse().GetResponseStream()
				$reader = New-Object System.IO.StreamReader($responseStream)
				$reader.ReadToEnd()
				$reader.Close()
			}
			catch { throw }
		}
	}
	
	function Write-SplunkMessage
	{
		[CmdletBinding()]
		param (
			$Message
		)
		
		$splunkUrl = Get-ConfigValue -Name 'Url'
		$splunkToken = Get-ConfigValue -Name 'Token'
		$properties = Get-ConfigValue -Name 'Properties'
		$name = Get-ConfigValue -Name 'LogName'
		
		$selectProps = switch ($properties)
		{
			'Message' { 'LogMessage as Message' }
			'Timestamp' { 'Timestamp.ToUniversalTime().ToString("yyyy-MM-dd_HH:mm:ss.fff") as Timestamp' }
			'Level' { 'Level to String' }
			'Type' { 'Type to String' }
			'CallStack' { 'CallStack to String' }
			'ErrorRecord' { 'ErrorRecord to String' }
			default { $_ }
		}
		$selectProps = @($selectProps) + @(@{ Name = 'LogName'; Expression = { $name } })
		
		$Message | Select-PSFObject $selectProps | Send-SplunkData -HostName $Message.ComputerName -Timestamp $Message.Timestamp -Uri $splunkUrl -Token $splunkToken
	}
}

$message_event = {
	param (
		$Message
	)
	Write-SplunkMessage -Message $Message
}

$configuration_Settings = {
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Splunk.Url' -Description 'The url to the Splunk http event collector. Example: https://localhost:8088/services/collector'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Splunk.Token' -Description 'The token used to authenticate to the Splunk event collector.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Splunk.Properties' -Initialize -Value 'Timestamp', 'Message', 'Level', 'Tags', 'FunctionName', 'ModuleName', 'Runspace', 'Username', 'ComputerName', 'TargetObject', 'Data' -Description 'The properties to write to Splunk.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Splunk.LogName' -Initialize -Value 'Undefined' -Validation string -Description 'Name associated with the task. Included in each entry, making it easier to reuse the same http event collector for multiple tasks.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Splunk.IgnoreCert' -Initialize -Value $false -Validation bool -Description 'Whether the server certificate should be validated or not.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Splunk.Index' -Initialize -Value '' -Validation string -Description 'The index to apply to all messages. Uses the splunk-defined default index if omitted.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Splunk.Source' -Initialize -Value '' -Validation string -Description 'Event source to add to all messages.'
	Set-PSFConfig -Module 'PSFramework' -Name 'Logging.Splunk.SourceType' -Initialize -Value '' -Validation string -Description 'Event source type to add to all messages.'
}

$paramRegisterPSFLoggingProvider = @{
	Name			   = "splunk"
	Version2		   = $true
	ConfigurationRoot  = 'PSFramework.Logging.Splunk'
	InstanceProperties = 'Url', 'Token', 'Properties', 'LogName', 'IgnoreCert', 'Index', 'Source', 'SourceType'
	MessageEvent	   = $message_Event
	ConfigurationSettings = $configuration_Settings
	FunctionDefinitions = $functionDefinitions
	ConfigurationDefaultValues = @{
		Properties = 'Timestamp', 'Message', 'Level', 'Tags', 'FunctionName', 'ModuleName', 'Runspace', 'Username', 'ComputerName', 'TargetObject', 'Data'
		LogName    = 'Undefined'
		IgnoreCert = $false
	}
}

# Register the Azure logging provider
Register-PSFLoggingProvider @paramRegisterPSFLoggingProvider