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
            #$SqlServer = Get-ConfigValue -Name 'Instance'
            $SqlServer = Get-PSFConfigValue -Name "PSFramework.Logging.Sql.SqlServer"
            $SqlDatabaseName = Get-PSFConfigValue -Name "PSFramework.Logging.Sql.LoggingDatabase"
        }

        process {

            $QueryParameters = @{
                "LogMessage"   = $ObjectToProcess.LogMessage
                "Level"        = $ObjectToProcess.Level.ToString()
                "TimeStamp"    = $ObjectToProcess.TimeStamp
                "FunctionName" = $ObjectToProcess.FunctionName
                "ModuleName"   = $ObjectToProcess.ModuleName
                "Tags"         = $ObjectToProcess.Tags -join ","
                "Runspace"     = $ObjectToProcess.Runspace
                "ComputerName" = $ObjectToProcess.ComputerName
                "TargetObject" = $ObjectToProcess.TargetObject -as [string]
                "ExecutedFile" = $ObjectToProcess.File -as [string]
                "Line"         = $ObjectToProcess.Line
                "ErrorRecord"  = $ObjectToProcess.ErrorRecord -as [string]
                "CallStack"    = $ObjectToProcess.CallStack.ToString()
            }

            $insertQuery = @"
INSERT INTO [LoggingDatabase].[dbo].[LoggingTable](LogMessage, Level, TimeStamp, FunctionName, ModuleName, Tags, Runspace, ComputerName, TargetObject, ExecutedFile, Line, ErrorRecord, CallStack)
VALUES ('$($QueryParameters.LogMessage)', '$($QueryParameters.Level)', '$($QueryParameters.TimeStamp)', '$($QueryParameters.FunctionName)', '$($QueryParameters.ModuleName)', '$($QueryParameters.Tags)', '$($QueryParameters.Runspace)', '$($QueryParameters.ComputerName)', '$($QueryParameters.TargetObject)', '$($QueryParameters.ExecutedFile)', '$($QueryParameters.Line)', '$($QueryParameters.ErrorRecord)', '$($QueryParameters.CallStack)')
"@
            try {
                $SqlInstance = Connect-DbaInstance -SqlInstance $SqlServer  # Creates an SMO Server object that connects using Windows Authentication.
                if ($SqlInstance.Status -eq 'Offline')
                { throw "$($SqlDatabaseName) is offline or unreachable." }
                elseif ($SqlInstance.ConnectionContext.IsOpen -ne 'True') {
                    $SqlInstance.ConnectionContext.Connect() # Try to connect to the database
                }
                Invoke-DbaQuery -SqlInstance $SqlInstance -Database $SqlDatabaseName -Query $insertQuery -EnableException
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
        param()

        #if (-NOT (Test-Path -Path 'C:\Users\sifu1\AppData\Local\Microsoft\Microsoft SQL Server Local DB\Instances\LoggingDatabase')) {
        #    New-Item -Name 'LoggingDatabase' -Path 'C:\Users\sifu1\AppData\Local\Microsoft\Microsoft SQL Server Local DB\Instances\' -ItemType Directory
        #}

        begin {

            # Load the appropriate .NET assemblies used by SMO
            [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')

            # set instance and database name variables
            $sqlInstance = "(localdb)\ProjectsV13"
        }
        process {
            try {
                # Create the Sql object and database
                $database = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -Argumentlist $sqlInstance, $SqlDatabaseName
                $database.Create()
                # set recovery model
                $database.RecoveryModel = "simple"
                $database.Alter()

                # Change the database owner
                $database.SetOwner('sa')

                $createtable = "CREATE TABLE LoggingTable (LogMessage VARCHAR(max), Level VARCHAR(max), TimeStamp [DATETIME], FunctionName VARCHAR(max), ModuleName VARCHAR(max), Tags VARCHAR(max), Runspace VARCHAR(36), ComputerName VARCHAR(max), TargetObject VARCHAR(max), ExecutedFile VARCHAR(max), Line BIGINT, ErrorRecord VARCHAR(max), CallStack VARCHAR(max))"
                invoke-dbaquery -SQLInstance $SqlServer -Database "LoggingDatabase" -query $createtable
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
    #New-DefaultSqlDatabaseAndTable
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
    Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.Database' -Value "LoggingDatabase" -Initialize -Validation 'string' -Description "SQL server database."
    Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.DatabaseTable' -Value "LoggingTable" -Initialize -Validation 'string' -Description "SQL server database table."
    Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.SqlServer' -Value "(localdb)\ProjectsV13" -Initialize -Validation 'string' -Description "SQL server hosting logs."
    Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.LogType' -Value "Message" -Initialize -Validation 'string' -Description "Log type we will log information to."
}

# Registered parameters for the logging provider.
# ConfigurationDefaultValues are used for all instances of the sql log provider
$paramRegisterPSFSqlProvider = @{
    Name                       = "Sql"
    Version2                   = $true
    ConfigurationRoot          = 'PSFramework.Logging.Sql'
    InstanceProperties         = 'Database', 'DatabaseTable', 'SqlServer', 'LogType'
    MessageEvent               = $message_Event
    BeginEvent                 = $begin_event
    FinalEvent                 = $final_event
    IsInstalledScript          = $isInstalled_script
    InstallationScript         = $installation_script
    ConfigurationSettings      = $configuration_Settings
    InstallationParameters     = $installationParameters
    FunctionDefinitions        = $functionDefinitions
    ConfigurationDefaultValues = @{
        LogType = 'Message'
    }
}

# Register the Azure logging provider
Register-PSFLoggingProvider @paramRegisterPSFSqlProvider