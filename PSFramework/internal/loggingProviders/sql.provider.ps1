$FunctionDefinitions = {
	function Get-DatabaseConnection {
		[CmdletBinding()]
		param ()

		if (-not $script:connections) {
			$script:connections = @{ }
		}

		# Connection already established
		if ($script:cfgServer.ConnectionContext) {
			$server = $script:cfgServer
		}
		elseif ($script:connections[$script:cfgServer]) {
			$server = $script:connections[$script:cfgServer]
		}
		else {
			$param = @{
				SqlInstance = $script:cfgServer
			}
			$credential = Get-ConfigValue -Name 'Credential'
			if ($credential) { $param.SqlCredential = $Credential }
			try { $server = Connect-DbaInstance @param -ErrorAction Stop }
			catch { throw }
			$script:connections[$script:cfgServer] = $server
		}
		if (-not $server.ConnectionContext.IsOpen) {
			try { $server.ConnectionContext.Connect() }
			catch { throw }
		}
		$server
	}

	function Export-DataToSql {
        <#
        .SYNOPSIS
            Function to send logging data to a Sql database

        .DESCRIPTION
            This function is the main function that takes a PSFMessage object to log in a Sql database.

        .PARAMETER ObjectToProcess
            This is a PSFMessage object that will be converted and serialized then injected to a Sql database.

        .EXAMPLE
            Export-DataToAzure $objectToProcess

        .NOTES
            How to register this provider
            -----------------------------
            Set-PSFLoggingProvider -Name sql -InstanceName sqlloginstance -Enabled $true
        #>
		
		[cmdletbinding()]
		param (
			[parameter(Mandatory = $True)]
			$ObjectToProcess
		)
		
		process {
			$queryParameters = @($script:converter.Process($ObjectToProcess))[0]
			$insertQuery = Get-Query -Parameters $queryParameters
			
			try {
				$sqlInstance = Get-DatabaseConnection
				
				Invoke-DbaQuery -SqlInstance $sqlInstance -Database $script:cfgDatabase -Query $insertQuery -SqlParameters $queryParameters -EnableException
			}
			catch { throw }
		}
	}
	
	function Get-Query {
		[CmdletBinding()]
		param (
			[hashtable]
			$Parameters
		)
		
		if ($script:insertQuery) { return $script:insertQuery }
		
		$properties = $Parameters.Keys
		$propSquared = foreach ($property in $properties) {
			"[$property]"
		}
		$propAdd = foreach ($property in $properties) {
			"@$property"
		}

		if ($script:cfgTable -match '\[|\]|\(|\)| ') {
			throw "Invalid Table name: $script:cfgTable"
		}
		if ($script:cfgSchema -match '\[|\]|\(|\)| ') {
			throw "Invalid Schema name: $script:cfgSchema"
		}
		
		$script:insertQuery = @"
INSERT INTO [$script:cfgDatabase].[$script:cfgSchema].[$script:cfgTable]($($propSquared -join ','))
VALUES ($($propAdd -join ','))
"@
		$script:insertQuery
	}
	
	function New-DefaultSqlDatabaseAndTable {
        <#
        .SYNOPSIS
                This function will create a default sql database object

        .DESCRIPTION
                This function will create the default sql default logging database

        .EXAMPLE
            None
        #>
		
		[cmdletbinding()]
		param (
		)
		
		# need to use dba tools to create the database and credentials for connecting.
		
		
		begin {
			# set instance and database name variables
			$SqlTable = Get-ConfigValue -Name 'Table'
			$SqlDatabaseName = Get-ConfigValue -Name 'Database'
			$SqlSchema = Get-ConfigValue -Name 'Schema'
			if (-not $SqlSchema) { $SqlSchema = 'dbo' }
			
			if ($SqlTable -match '\[|\]|\(|\)| ') {
				throw "Invalid Table name: $SqlTable"
			}
			if ($SqlSchema -match '\[|\]|\(|\)| ') {
				throw "Invalid Schema name: $SqlSchema"
			}
		}
		process {
			try {
				$dbaconnection = Get-DatabaseConnection
				$database = Get-DbaDatabase -SqlInstance $dbaconnection | Where-Object Name -eq $SqlDatabaseName
				if (-NOT $database) {
					$database = New-DbaDatabase -SqlInstance $dbaconnection -Name $SqlDatabaseName
				}
				if (-NOT ($database.Tables | Where-Object Name -eq $SqlTable)) {
					$createtable = "CREATE TABLE $SqlSchema.$SqlTable (Message VARCHAR(max), Level VARCHAR(max), TimeStamp [DATETIME], FunctionName VARCHAR(max), ModuleName VARCHAR(max), Tags VARCHAR(max), Runspace VARCHAR(36), ComputerName VARCHAR(max), Username VARCHAR(max), TargetObject VARCHAR(max), [File] VARCHAR(max), Line BIGINT, ErrorRecord VARCHAR(max), CallStack VARCHAR(max), [Data] VARCHAR(max))"
					Invoke-dbaquery -SQLInstance $dbaconnection -Database $SqlDatabaseName -Query $createtable
				}
			}
			catch {
				throw
			}
		}
	}
}

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
		Name = 'dbatools'
	}
	if ($BoundParameters.Scope) { $paramInstallModule['Scope'] = $BoundParameters.Scope }
	elseif (-not (Test-PSFPowerShell -Elevated)) { $paramInstallModule['Scope'] = 'CurrentUser' }
	if ($BoundParameters.Repository) { $paramInstallModule['Repository'] = $BoundParameters.Repository }
	else { $paramInstallModule['Repository'] = Get-PSFConfigValue -FullName 'PSFramework.System.DefaultRepository' -Fallback 'PSGallery' }
	
	Install-Module @paramInstallModule
}

$isInstalled_script = {
	(Get-Module dbatools -ListAvailable) -as [bool]
}
#endregion Installation
#region Events
$begin_event = {
	$script:cfgServer = Get-ConfigValue -Name 'SqlServer'

	New-DefaultSqlDatabaseAndTable
}
$start_event = {
	$changePending = $false
	if ($script:cfgHeaders -ne (Get-ConfigValue -Name 'Headers')) {
		$script:cfgHeaders = Get-ConfigValue -Name 'Headers'
		$changePending = $true
	}
	if ($script:cfgServer -ne (Get-ConfigValue -Name 'SqlServer')) {
		$script:cfgServer = Get-ConfigValue -Name 'SqlServer'
		$changePending = $true
	}
	if ($script:cfgDatabase -ne (Get-ConfigValue -Name 'Database')) {
		$script:cfgDatabase = Get-ConfigValue -Name 'Database'
		$changePending = $true
	}
	if ($script:cfgSchema -ne (Get-ConfigValue -Name 'Schema')) {
		$script:cfgSchema = Get-ConfigValue -Name 'Schema'
		if (-not $script:cfgSchema) { $script:cfgSchema = 'dbo' }
		$changePending = $true
	}
	if ($script:cfgTable -ne (Get-ConfigValue -Name 'Table')) {
		$script:cfgTable = Get-ConfigValue -Name 'Table'
		$changePending = $true
	}
	if (-not $changePending) { return }
	
	$script:sql_headers = switch ($script:cfgHeaders) {
		'Tags'
		{
			@{
				Name	   = 'Tags'
				Expression = { ($_.Tags -join ",") -as [string] }
			}
		}
		'Message' { @{ Name = 'Message'; Expression = { $_.LogMessage } } }
		'Level' { @{ Name = 'Level'; Expression = { $_.Level -as [string] } } }
		'Runspace' { @{ Name = 'Runspace'; Expression = { $_.Runspace -as [string] } } }
		'TargetObject' { @{ Name = 'TargetObject'; Expression = { $_.TargetObject -as [string] } } }
		'ErrorRecord' { @{ Name = 'ErrorRecord'; Expression = { $_.ErrorRecord -as [string] } } }
		'CallStack' { @{ Name = 'CallStack'; Expression = { $_.CallStack -as [string] } } }
		'Timestamp'
		{
			@{
				Name						   = 'Timestamp'
				Expression					   = {
					$_.Timestamp.ToUniversalTime()
				}
			}
		}
		'Data'
		{
			@{
				Name = 'Data'
				Expression = {
					if (-not $_.Data) { return 'null' }
					$_.Data | ConvertTo-Json -Compress
				}
			}
		}
		default { $_ }
	}
	
	if ($script:converter) {
		$null = $script:converter.End()
		$script:converter = $null
	}
	# Cache the conversion logic once as a steppable pipeline to avoid having to do it
	$script:converter = { Microsoft.PowerShell.Utility\Select-Object $script:sql_headers | PSFramework\ConvertTo-PSFHashtable }.GetSteppablePipeline()
	$script:converter.Begin($true)
	
	$script:insertQuery = ''
}

$message_event = {
	param (
		$Message
	)
	
	Export-DataToSql -ObjectToProcess $Message
}

$end_event = {
	if ($script:converter) {
		$null = $script:converter.End()
		$script:converter = $null
	}
}

# Action that is performed when stopping the logging script.
$final_event = {
	
}
#endregion Events

# Configuration values for the logging provider
$configuration_Settings = {
	Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.Credential' -Initialize -Validation 'credential' -Description "Credentials used for connecting to the SQL server."
	Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.Database' -Value "LoggingDatabase" -Initialize -Validation 'string' -Description "SQL server database."
	Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.Table' -Value "LoggingTable" -Initialize -Validation 'string' -Description "SQL server database table."
	Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.SqlServer' -Value "" -Initialize -Description "SQL server hosting logs."
	Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.Schema' -Value "dbo" -Initialize -Description "SQL server schema."
}

# Registered parameters for the logging provider.
# ConfigurationDefaultValues are used for all instances of the sql log provider
$paramRegisterPSFSqlProvider = @{
	Name			   = "Sql"
	Version2		   = $true
	ConfigurationRoot  = 'PSFramework.Logging.Sql'
	InstanceProperties = 'Database', 'Schema', 'Table', 'SqlServer', 'Credential', 'Headers'
	MessageEvent	   = $message_Event
	BeginEvent		   = $begin_event
	StartEvent		   = $start_event
	EndEvent		   = $end_event
	FinalEvent		   = $final_event
	IsInstalledScript  = $isInstalled_script
	InstallationScript = $installation_script
	ConfigurationSettings = $configuration_Settings
	InstallationParameters = $installationParameters
	FunctionDefinitions = $functionDefinitions
	ConfigurationDefaultValues = @{
		'Database' = "LoggingDatabase"
		'Table'    = "LoggingTable"
		'Schema'   = 'dbo'
		Headers    = 'Message', 'Timestamp', 'Level', 'Tags', 'Data', 'ComputerName', 'Runspace', 'UserName', 'ModuleName', 'FunctionName', 'File', 'Line', 'CallStack', 'TargetObject', 'ErrorRecord'
	}
}

# Register the Azure logging provider
Register-PSFLoggingProvider @paramRegisterPSFSqlProvider