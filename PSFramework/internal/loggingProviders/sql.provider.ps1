$FunctionDefinitions = {

    Function Export-DataToSql {
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
            Set-PSFLoggingProvider -Name sqllog -InstanceName sqlloginstance -Enabled $true
        #>

        [cmdletbinding()]
        param(
            [parameter(Mandatory = $True)]
            $ObjectToProcess
        )

        begin {
            $SqlServer = Get-ConfigValue -Name 'SqlServer'
            $SqlTable = Get-ConfigValue -Name 'Table'
            $SqlDatabaseName = Get-ConfigValue -Name 'Database'
        }

        process {
            $QueryParameters = @{
                "Message"      = $ObjectToProcess.LogMessage
                "Level"        = $ObjectToProcess.Level -as [string]
                "TimeStamp"    = $ObjectToProcess.TimeStamp.ToUniversalTime()
                "FunctionName" = $ObjectToProcess.FunctionName
                "ModuleName"   = $ObjectToProcess.ModuleName
                "Tags"         = $ObjectToProcess.Tags -join "," -as [string]
                "Runspace"     = $ObjectToProcess.Runspace -as [string]
                "ComputerName" = $ObjectToProcess.ComputerName
                "TargetObject" = $ObjectToProcess.TargetObject -as [string]
                "File"         = $ObjectToProcess.File
                "Line"         = $ObjectToProcess.Line
                "ErrorRecord"  = $ObjectToProcess.ErrorRecord -as [string]
                "CallStack"    = $ObjectToProcess.CallStack -as [string]
            }

            try {
                $SqlInstance = Connect-DbaInstance -SqlInstance $SqlServer
                if ($SqlInstance.ConnectionContext.IsOpen -ne 'True') {
                    $SqlInstance.ConnectionContext.Connect() # Try to connect to the database
                }

                $insertQuery = "INSERT INTO [$SqlDatabaseName].[dbo].[$SqlTable](Message, Level, TimeStamp, FunctionName, ModuleName, Tags, Runspace, ComputerName, TargetObject, [File], Line, ErrorRecord, CallStack)
                VALUES (@Message, @Level, @TimeStamp, @FunctionName, @ModuleName, @Tags, @Runspace, @ComputerName, @TargetObject, @File, @Line, @ErrorRecord, @CallStack)"
                Invoke-DbaQuery -SqlInstance $SqlInstance -Database $SqlDatabaseName -Query $insertQuery -SqlParameters $QueryParameters -EnableException
            }
            catch { throw }
        }
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
        param(
        )

        # need to use dba tools to create the database and credentials for connecting.


        begin {

            # set instance and database name variables
            $Credential = Get-ConfigValue -Name 'Credential'
            $SqlServer = Get-ConfigValue -Name 'SqlServer'
            $SqlTable = Get-ConfigValue -Name 'Table'
            $SqlDatabaseName = Get-ConfigValue -Name 'Database'

            $parameters = @{
                SqlInstance = $SqlServer
            }
            if ($Credential) { $parameters.SqlCredential = $Credential }
        }
        process {
            try {
                $dbaconnection = Connect-DbaInstance @parameters
                if (-NOT (Get-DbaDatabase -SqlInstance $dbaconnection | Where-Object Name -eq $SqlDatabaseName)) {
                    $database = New-DbaDatabase -SqlInstance $dbaconnection -Name $SqlDatabaseName
                }
                if (-NOT($database.Tables | Where-Object Name -eq $SqlTable)) {
                    $createtable = "CREATE TABLE $SqlTable (Message VARCHAR(max), Level VARCHAR(max), TimeStamp [DATETIME], FunctionName VARCHAR(max), ModuleName VARCHAR(max), Tags VARCHAR(max), Runspace VARCHAR(36), ComputerName VARCHAR(max), TargetObject VARCHAR(max), [File] VARCHAR(max), Line BIGINT, ErrorRecord VARCHAR(max), CallStack VARCHAR(max))"
                    Invoke-dbaquery -SQLInstance $SqlServer -Database $SqlDatabaseName -query $createtable
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

    $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter("Scope", [string], $attributesCollection)
    $results.Add("Scope", $RuntimeParam)
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

    Install-Module @paramInstallModule
}

$isInstalled_script = {
    (Get-Module dbatools -ListAvailable) -as [bool]
}
#endregion Installation
#region Events
$begin_event = {
    New-DefaultSqlDatabaseAndTable
}

$message_event = {
    param (
        $Message
    )

    Export-DataToSql -ObjectToProcess $Message
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
}

# Registered parameters for the logging provider.
# ConfigurationDefaultValues are used for all instances of the sql log provider
$paramRegisterPSFSqlProvider = @{
    Name                       = "Sql"
    Version2                   = $true
    ConfigurationRoot          = 'PSFramework.Logging.Sql'
    InstanceProperties         = 'Database', 'Table', 'SqlServer', 'Credential'
    MessageEvent               = $message_Event
    BeginEvent                 = $begin_event
    FinalEvent                 = $final_event
    IsInstalledScript          = $isInstalled_script
    InstallationScript         = $installation_script
    ConfigurationSettings      = $configuration_Settings
    InstallationParameters     = $installationParameters
    FunctionDefinitions        = $functionDefinitions
    ConfigurationDefaultValues = @{
        'Database'  = "LoggingDatabase"
        'Table'     = "LoggingTable"
    }
}

# Register the Azure logging provider
Register-PSFLoggingProvider @paramRegisterPSFSqlProvider