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
            $SqlServer = "(localdb)\ProjectsV13"
        }

        process {

            $QueryParameters = @{
                "Message"      = $ObjectToProcess.LogMessage
                "Level"        = $ObjectToProcess.Level
                "TimeStamp"    = $ObjectToProcess.TimeStamp
                "FunctionName" = $ObjectToProcess.FunctionName
                "ModuleName"   = $ObjectToProcess.ModuleName
                "Tags"         = $ObjectToProcess.Tags
                "Runspace"     = $ObjectToProcess.Runspace
                "ComputerName" = $ObjectToProcess.ComputerName
                "TargetObject" = $ObjectToProcess.TargetObject
                "File"         = $ObjectToProcess.File
                "Line"         = $ObjectToProcess.Line
                "ErrorRecord"  = $ObjectToProcess.ErrorRecord
                "CallStack"    = $ObjectToProcess.CallStack
            }

            $insertQuery = "INSERT INTO TABLE LoggingTable VALUES ($($QueryParameters.Message), $($QueryParameters.Level), $($QueryParameters.TimeStamp),`
                $($QueryParameters.FunctionName), $($QueryParameters.Tags), $($QueryParameters.RunSpace), $($QueryParameters.ComputerName),`
                $($QueryParameters.TargetObject), $($QueryParameters.File), $($QueryParameters.Line), $($QueryParameters.ErrorRecord), $($QueryParameters.CallStack))"

            try {
                Write-PSFMessage -Level Verbose -Message "Testing connection to Sql database on {0}" -StringValues $SqlServer
                $SqlInstance = Connect-ToSqlInstance -SqlInstance $SqlServer
                $database = $SqlInstance.databases | Where-Object Name -match "LoggingDatabase"
                Write-PSFMessage -Level Verbose -Message "Calling Invoke-DbaQuery"
                Invoke-DbaQuery -SqlInstance $SqlInstance.Name -Database $database -Query $insertQuery -SqlParameters $QueryParameters
            }
            catch { throw }
            Finally {
                if ($SqlInstance.ConnectionContext.IsOpen -eq $True) {
                    Write-PSFMessage -Level Verbose -Message "Closing database connection to {0}\{1}" -StringValues $SqlInstance.ComputerName, $SqlInstance.DbaInstanceName
                    $SqlInstance.ConnectionContext.Disconnect
                }
            }
        }
    }

    Function Connect-ToSqlInstance {
        <#
    .SYNOPSIS
        Function to send logging data to a Sql database

    .DESCRIPTION
        This function is the main function that takes a PSFMessage object to log in a Sql database.

    .PARAMETER ObjectToProcess
        This is a PSFMessage object that will be converted and serialized then injected to a Sql database.

    .EXAMPLE
        ConnectTo-SqlInstance -SqlServer SQLServerName

    .NOTES
        How to register this provider
        -----------------------------
        Set-PSFLoggingProvider -Name sqllog -InstanceName sqlloginstance -Enabled $true
    #>

        [cmdletbinding()]
        param(
            $ObjectToProcess,

            [DbaInstance[]]
            $SqlInstance,

            [PsCredential]
            $SqlCredential,

            [string]
            $Database,

            [string]
            $connString,

            [System.Data.Common.DbConnectionStringBuilder]
            $sb,

            [string]
            $ClientName = "PSFramework - Sql Logging Provider",

            [string]
            $AuthenticationType = "Auto",

            [bool]
            $EnableException = $false
        )

        begin {
            # Search the local AppDomain and get all loaded Smo versions
            $loadedSmoVersion = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.Fullname -like "Microsoft.SqlServer.SMO,*" }

            if ($loadedSmoVersion) {
                $loadedSmoVersion = $loadedSmoVersion | ForEach-Object {
                    if ($_.Location -match "__") {
                        ((Split-Path (Split-Path $_.Location) -Leaf) -split "__")[0]
                    }
                    else {
                        ((Get-ChildItem -Path $_.Location).VersionInfo.ProductVersion)
                    }
                }
            }

            #'PrimaryFilePath' seems the culprit for slow SMO on databases
            $Fields2000_Db = 'Collation', 'CompatibilityLevel', 'CreateDate', 'ID', 'IsAccessible', 'IsFullTextEnabled', 'IsSystemObject', 'IsUpdateable', 'LastBackupDate', 'LastDifferentialBackupDate', 'LastLogBackupDate', 'Name', 'Owner', 'ReadOnly', 'RecoveryModel', 'ReplicationOptions', 'Status', 'Version'
            $Fields200x_Db = $Fields2000_Db + @('BrokerEnabled', 'DatabaseSnapshotBaseName', 'IsMirroringEnabled', 'Trustworthy')
            $Fields201x_Db = $Fields200x_Db + @('ActiveConnections', 'AvailabilityDatabaseSynchronizationState', 'AvailabilityGroupName', 'ContainmentType', 'EncryptionEnabled')

            $Fields2000_Login = 'CreateDate', 'DateLastModified', 'DefaultDatabase', 'DenyWindowsLogin', 'IsSystemObject', 'Language', 'LanguageAlias', 'LoginType', 'Name', 'Sid', 'WindowsLoginAccessType'
            $Fields200x_Login = $Fields2000_Login + @('AsymmetricKey', 'Certificate', 'Credential', 'ID', 'IsDisabled', 'IsLocked', 'IsPasswordExpired', 'MustChangePassword', 'PasswordExpirationEnabled', 'PasswordPolicyEnforced')
            $Fields201x_Login = $Fields200x_Login + @('PasswordHashAlgorithm')
        }

        process {
            # Check to see if we passed in a connection string
            if ($SqlInstance.IsConnectionString) {
                $connstring = $SqlInstance.InputObject
                $isConnectionString = $true
            }
            if ($SqlInstance.Type -eq 'RegisteredServer' -and $SqlInstance.InputObject.ConnectionString) {
                $connstring = $SqlInstance.InputObject.ConnectionString
                $isConnectionString = $true
            }

            if ($isConnectionString) {
                try {
                    # ensure it's in the proper format
                    $sb = New-Object System.Data.Common.DbConnectionStringBuilder
                    $sb.ConnectionString = $connstring
                }
                catch {
                    $isConnectionString = $false
                }
            }

            #region Safely convert input into instance parameters
            <#
            This is a bit ugly, but:
            In some cases functions would directly pass their own input through when the parameter on the calling function was typed as [object[]].
            This would break the base parameter class, as it'd automatically be an array and the parameterclass is not designed to handle arrays (Shouldn't have to).
            Note: Multiple servers in one call were never supported, those old functions were liable to break anyway and should be fixed soonest.
        #>
            if ($SqlInstance.GetType() -eq [Sqlcollaborative.Dbatools.Parameter.DbaInstanceParameter]) {
                [DbaInstanceParameter]$SqlInstance = $SqlInstance
                if ($SqlInstance.Type -like "SqlConnection") {
                    [DbaInstanceParameter]$SqlInstance = New-Object Microsoft.SqlServer.Management.Smo.Server($SqlInstance.InputObject)
                }
            }
            else {
                [DbaInstanceParameter]$SqlInstance = [DbaInstanceParameter]($SqlInstance | Select-Object -First 1)

                if ($SqlInstance.Count -gt 1) {
                    Stop-PSFunction -Level Verbose -Message "More than on server was specified when calling Connect-SqlInstance from $((Get-PSCallStack)[1].Command)" -Continue -EnableException:$EnableException
                }
            }
            #endregion Safely convert input into instance parameters

            #region Input Object was a server object
            if ($SqlInstance.Type -like "Server" -or ($isAzure -and $SqlInstance.InputObject.ConnectionContext.IsOpen)) {
                if ($SqlInstance.InputObject.ConnectionContext.IsOpen -eq $false) {
                    $SqlInstance.InputObject.ConnectionContext.Connect()
                }
                if ($SqlConnectionOnly) {
                    $SqlInstance.InputObject.ConnectionContext.SqlConnectionObject
                    continue
                }
                else {
                    $SqlInstance.InputObject
                    [Sqlcollaborative.Dbatools.TabExpansion.TabExpansionHost]::SetInstance($SqlInstance.FullSmoName.ToLowerInvariant(), $SqlInstance.InputObject.ConnectionContext.Copy(), ($SqlInstance.InputObject.ConnectionContext.FixedServerRoles -match "SysAdmin"))

                    # Update cache for instance names
                    if ([Sqlcollaborative.Dbatools.TabExpansion.TabExpansionHost]::Cache["sqlinstance"] -notcontains $SqlInstance.FullSmoName.ToLowerInvariant()) {
                        [Sqlcollaborative.Dbatools.TabExpansion.TabExpansionHost]::Cache["sqlinstance"] += $SqlInstance.FullSmoName.ToLowerInvariant()
                    }
                    continue
                }
            }
            #endregion Input Object was a server object

            if ($SqlInstance.Type -like "SqlConnection") {
                $server = New-Object Microsoft.SqlServer.Management.Smo.Server($SqlInstance.InputObject)

                if ($server.ConnectionContext.IsOpen -eq $false) {
                    $server.ConnectionContext.Connect()
                }
                if ($SqlConnectionOnly) {
                    if ($MinimumVersion -and $server.VersionMajor) {
                        if ($server.versionMajor -lt $MinimumVersion) {
                            Stop-PSFunction -Level Verbose -Message "SQL Server version $MinimumVersion required - $server not supported." -Continue
                        }
                    }

                    if ($AzureUnsupported -and $server.DatabaseEngineType -eq "SqlAzureDatabase") {
                        Stop-PSFunction -Level Verbose -Message "Azure SQL Database not supported" -Continue
                    }
                    $server.ConnectionContext.SqlConnectionObject
                    continue
                }
                else {
                    if (-not $server.ComputerName) {
                        Add-Member -InputObject $server -NotePropertyName IsAzure -NotePropertyValue $false -Force
                        Add-Member -InputObject $server -NotePropertyName ComputerName -NotePropertyValue $SqlInstance.ComputerName -Force
                        Add-Member -InputObject $server -NotePropertyName DbaInstanceName -NotePropertyValue $SqlInstance.InstanceName -Force
                        Add-Member -InputObject $server -NotePropertyName NetPort -NotePropertyValue $SqlInstance.Port -Force
                        Add-Member -InputObject $server -NotePropertyName ConnectedAs -NotePropertyValue $server.ConnectionContext.TrueLogin -Force
                    }
                    if ($MinimumVersion -and $server.VersionMajor) {
                        if ($server.versionMajor -lt $MinimumVersion) {
                            Stop-PSFunction -Level Verbose -Message "SQL Server version $MinimumVersion required - $server not supported." -Continue
                        }
                    }

                    if ($AzureUnsupported -and $server.DatabaseEngineType -eq "SqlAzureDatabase") {
                        Stop-PSFunction -Level Verbose -Message "Azure SQL Database not supported" -Continue
                    }

                    [Sqlcollaborative.Dbatools.TabExpansion.TabExpansionHost]::SetInstance($SqlInstance.FullSmoName.ToLowerInvariant(), $server.ConnectionContext.Copy(), ($server.ConnectionContext.FixedServerRoles -match "SysAdmin"))
                    # Update cache for instance names
                    if ([Sqlcollaborative.Dbatools.TabExpansion.TabExpansionHost]::Cache["sqlinstance"] -notcontains $SqlInstance.FullSmoName.ToLowerInvariant()) {
                        [Sqlcollaborative.Dbatools.TabExpansion.TabExpansionHost]::Cache["sqlinstance"] += $SqlInstance.FullSmoName.ToLowerInvariant()
                    }
                    $server
                    continue
                }
            }

            if ($isConnectionString) {
                # this is the way, as recommended by Microsoft
                # https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/configure-always-encrypted-using-powershell?view=sql-server-2017
                $sqlconn = New-Object System.Data.SqlClient.SqlConnection $connstring
                $serverconn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection $sqlconn
                $null = $serverconn.Connect()
                $server = New-Object Microsoft.SqlServer.Management.Smo.Server $serverconn
            }
            elseif (-not $isAzure) {
                $server = New-Object Microsoft.SqlServer.Management.Smo.Server($SqlInstance.FullSmoName)
            }

            if ($AppendConnectionString) {
                $connstring = $server.ConnectionContext.ConnectionString
                $server.ConnectionContext.ConnectionString = "$connstring;$appendconnectionstring"
                $server.ConnectionContext.Connect()
            }
            elseif (-not $isAzure -and -not $isConnectionString) {
                # It's okay to skip Azure because this is addressed above with New-DbaConnectionString
                #$server.ConnectionContext.ApplicationName = $ClientName

                # WE USE THIS
                if ($connstring -ne $server.ConnectionContext.ConnectionString) {
                    $server.ConnectionContext.ConnectionString = $connstring
                }

                try {
                    # parse out sql credential to figure out if it's Windows or SQL Login
                    if ($null -ne $SqlCredential.UserName -and -not $isAzure) {
                        $username = ($SqlCredential.UserName).TrimStart("\")

                        # support both ad\username and username@ad
                        if ($username -like "*\*" -or $username -like "*@*") {
                            if ($username -like "*\*") {
                                $domain, $login = $username.Split("\")
                                $authtype = "Windows Authentication with Credential"
                                if ($domain) {
                                    $formatteduser = "$login@$domain"
                                }
                                else {
                                    $formatteduser = $username.Split("\")[1]
                                }
                            }
                            else {
                                $formatteduser = $SqlCredential.UserName
                            }

                            $server.ConnectionContext.LoginSecure = $true
                            $server.ConnectionContext.ConnectAsUser = $true
                            $server.ConnectionContext.ConnectAsUserName = $formatteduser
                            $server.ConnectionContext.ConnectAsUserPassword = ($SqlCredential).GetNetworkCredential().Password
                        }
                        else {
                            $authtype = "SQL Authentication"
                            $server.ConnectionContext.LoginSecure = $false
                            $server.ConnectionContext.set_Login($username)
                            $server.ConnectionContext.set_SecurePassword($SqlCredential.Password)
                        }
                    }

                    Write-PSFMessage -Level Verbose -Message "Opening database connection to {0}" -StringValues $server.name

                    if ($NonPooled) {
                        # When the Connect method is called, the connection is not automatically released.
                        # The Disconnect method must be called explicitly to release the connection to the connection pool.
                        # https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/create-program/disconnecting-from-an-instance-of-sql-server
                        $server.ConnectionContext.Connect()
                    }
                    elseif ($authtype -eq "Windows Authentication with Credential") {
                        # Make it connect in a natural way, hard to explain.
                        # See https://docs.microsoft.com/en-us/sql/relational-databases/server-management-objects-smo/create-program/connecting-to-an-instance-of-sql-server
                        $null = $server.Information.Version
                        if ($server.ConnectionContext.IsOpen -eq $false) {
                            # Sometimes, however, the above may not connect as promised. Force it.
                            # See https://github.com/sqlcollaborative/dbatools/pull/4426
                            $server.ConnectionContext.Connect()
                        }
                    }
                    else {
                        if (-not $isAzure) {
                            # SqlConnectionObject.Open() enables connection pooling does not support
                            # alternative Windows Credentials and passes default credentials
                            # See https://github.com/sqlcollaborative/dbatools/pull/3809
                            $server.ConnectionContext.SqlConnectionObject.Open()
                        }
                    }
                }
                catch {
                    $originalException = $_.Exception
                    try {
                        $message = $originalException.InnerException.InnerException.ToString()
                    }
                    catch {
                        $message = $originalException.ToString()
                    }
                    $message = ($message -Split '-->')[0]
                    $message = ($message -Split 'at System.Data.SqlClient')[0]
                    $message = ($message -Split 'at System.Data.ProviderBase')[0]

                    Stop-PSFFunction -Level Verbose -Message "Can't connect to $SqlInstance" -ErrorRecord $_ -Continue
                }
            }

            # By default, SMO initializes several properties. We push it to the limit and gather a bit more
            # this slows down the connect a smidge but drastically improves overall performance
            # especially when dealing with a multitude of servers
            if ($loadedSmoVersion -ge 11 -and -not $isAzure) {
                # 2012 and above
                $initFieldsDb = New-Object System.Collections.Specialized.StringCollection
                [void]$initFieldsDb.AddRange($Fields201x_Db)
                $initFieldsLogin = New-Object System.Collections.Specialized.StringCollection
                [void]$initFieldsLogin.AddRange($Fields201x_Login)
                $server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Database], $initFieldsDb)
                $server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Login], $initFieldsLogin)
            }

            if ($SqlConnectionOnly) {
                $server.ConnectionContext.SqlConnectionObject
                continue
            }
            else {
                if (-not $server.ComputerName) {
                    # Not every environment supports .NetName
                    if ($server.DatabaseEngineType -ne "SqlAzureDatabase") {
                        try {
                            $computername = $server.NetName
                        }
                        catch {
                            $computername = $SqlInstance.ComputerName
                        }
                    }
                    # SQL on Linux is often on docker and the internal name is not useful
                    if (-not $computername -or $server.HostPlatform -eq "Linux") {
                        $computername = $SqlInstance.ComputerName
                    }
                    Add-Member -InputObject $server -NotePropertyName IsAzure -NotePropertyValue $false -Force
                    Add-Member -InputObject $server -NotePropertyName ComputerName -NotePropertyValue $computername -Force
                    Add-Member -InputObject $server -NotePropertyName DbaInstanceName -NotePropertyValue $SqlInstance.InstanceName -Force
                    Add-Member -InputObject $server -NotePropertyName NetPort -NotePropertyValue $SqlInstance.Port -Force
                    Add-Member -InputObject $server -NotePropertyName ConnectedAs -NotePropertyValue $server.ConnectionContext.TrueLogin -Force
                }
            }
            return $server
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
                Write-PSFMessage -Level Verbose -Message "Creating new Sql database {0}" -StringValues $SqlDatabaseName
                # Create the Sql object and database
                $database = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -Argumentlist $sqlInstance, $SqlDatabaseName
                $database.Create()
                # set recovery model
                $database.RecoveryModel = "simple"
                $database.Alter()

                # Change the database owner
                $database.SetOwner('sa')

                Write-PSFMessage -Level Verbose -Message "Creating new Sql database table {0}" -StringValues $SqlDatabaseTableName
                $createtable = "CREATE TABLE LoggingTable (LogMessage VARCHAR(max), Level VARCHAR(max), TimeStamp DateTime, FunctionName VARCHAR(max), ModuleName VARCHAR(max), Tags VARCHAR(max), Runspace VARCHAR(36), ComputerName VARCHAR(max), TargetObject VARCHAR(max), ExecutedFile VARCHAR(max), Line TINYINT, ErrorRecord VARCHAR(max), CallStack VARCHAR(max))"
                invoke-dbaquery -SQLInstance $SqlServer -Database "LoggingDatabase" -query $createtable
            }
            catch {
                throw
            }
        }
    }

    function Invoke-DbaQuery {
        <#
        .SYNOPSIS
            A command to run explicit T-SQL commands or files.

        .DESCRIPTION
            This function is a wrapper command around Invoke-DbaAsync, which in turn is based on Invoke-SqlCmd2.
            It was designed to be more convenient to use in a pipeline and to behave in a way consistent with the rest of our functions.

        .PARAMETER SqlInstance
            The target SQL Server instance or instances. This can be a collection and receive pipeline input to allow the function to be executed against multiple SQL Server instances.

        .PARAMETER SqlCredential
            Credential object used to connect to the SQL Server Instance as a different user. This can be a Windows or SQL Server account. Windows users are determined by the existence of a backslash, so if you are intending to use an alternative Windows connection instead of a SQL login, ensure it contains a backslash.

        .PARAMETER Database
            The database to select before running the query. This list is auto-populated from the server.

        .PARAMETER Query
            Specifies one or more queries to be run. The queries can be Transact-SQL, XQuery statements, or sqlcmd commands. Multiple queries in a single batch may be separated by a semicolon or a GO
            Escape any double quotation marks included in the string.
            Consider using bracketed identifiers such as [MyTable] instead of quoted identifiers such as "MyTable".

        .PARAMETER QueryTimeout
            Specifies the number of seconds before the queries time out.

        .PARAMETER File
            Specifies the path to one or several files to be used as the query input.

        .PARAMETER SqlObject
            Specify one or more SQL objects. Those will be converted to script and their scripts run on the target system(s).

        .PARAMETER As
            Specifies output type. Valid options for this parameter are 'DataSet', 'DataTable', 'DataRow', 'PSObject', and 'SingleValue'
            PSObject output introduces overhead but adds flexibility for working with results: http://powershell.org/wp/forums/topic/dealing-with-dbnull/

        .PARAMETER SqlParameters
            Specifies a hashtable of parameters for parameterized SQL queries.  http://blog.codinghorror.com/give-me-parameterized-sql-or-give-me-death/

        .PARAMETER AppendServerInstance
            If this switch is enabled, the SQL Server instance will be appended to PSObject and DataRow output.

        .PARAMETER MessagesToOutput
            Use this switch to have on the output stream messages too (e.g. PRINT statements). Output will hold the resultset too.

        .PARAMETER InputObject
            A collection of databases (such as returned by Get-DbaDatabase)

        .PARAMETER EnableException
            By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
            This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
            Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

        .PARAMETER ReadOnly
            Execute the query with ReadOnly application intent.

        .PARAMETER CommandType
            Specifies the type of command represented by the query string.  Default is Text

        .NOTES
            Tags: Database, Query
            Author: Friedrich Weinmann (@FredWeinmann)
            Website: https://dbatools.io
            Copyright: (c) 2018 by dbatools, licensed under MIT
            License: MIT https://opensource.org/licenses/MIT

        .LINK
            https://dbatools.io/Invoke-DbaQuery

        .EXAMPLE
            PS C:\> Invoke-DbaQuery -SqlInstance server\instance -Query 'SELECT foo FROM bar'
            Runs the sql query 'SELECT foo FROM bar' against the instance 'server\instance'

        .EXAMPLE
            PS C:\> Get-DbaRegServer -SqlInstance [SERVERNAME] -Group [GROUPNAME] | Invoke-DbaQuery -Query 'SELECT foo FROM bar'
            Runs the sql query 'SELECT foo FROM bar' against all instances in the group [GROUPNAME] on the CMS [SERVERNAME]

        .EXAMPLE
            PS C:\> "server1", "server1\nordwind", "server2" | Invoke-DbaQuery -File "C:\scripts\sql\rebuild.sql"
            Runs the sql commands stored in rebuild.sql against the instances "server1", "server1\nordwind" and "server2"

        .EXAMPLE
            PS C:\> Get-DbaDatabase -SqlInstance "server1", "server1\nordwind", "server2" | Invoke-DbaQuery -File "C:\scripts\sql\rebuild.sql"
            Runs the sql commands stored in rebuild.sql against all accessible databases of the instances "server1", "server1\nordwind" and "server2"

        .EXAMPLE
            PS C:\> Invoke-DbaQuery -SqlInstance . -Query 'SELECT * FROM users WHERE Givenname = @name' -SqlParameters @{ Name = "Maria" }
            Executes a simple query against the users table using SQL Parameters.
            This avoids accidental SQL Injection and is the safest way to execute queries with dynamic content.
            Keep in mind the limitations inherent in parameters - it is quite impossible to use them for content references.
            While it is possible to parameterize a where condition, it is impossible to use this to select which columns to select.
            The inserted text will always be treated as string content, and not as a reference to any SQL entity (such as columns, tables or databases).

        .EXAMPLE
            PS C:\> Invoke-DbaQuery -SqlInstance aglistener1 -ReadOnly -Query "select something from readonlydb.dbo.atable"
            Executes a query with ReadOnly application intent on aglistener1.

        .EXAMPLE
            PS C:\> Invoke-DbaQuery -SqlInstance "server1" -Database tempdb -Query "Example_SP" -SqlParameters @{ Name = "Maria" } -CommandType StoredProcedure
            Executes a stored procedure Example_SP using SQL Parameters

        .EXAMPLE
            PS C:\> $QueryParameters = @{
                "StartDate" = $startdate;
                "EndDate" = $enddate;
            };

            PS C:\> Invoke-DbaQuery -SqlInstance "server1" -Database tempdb -Query "Example_SP" -SqlParameters $QueryParameters -CommandType StoredProcedure
            Executes a stored procedure Example_SP using multiple SQL Parameters
        #>
        [CmdletBinding(DefaultParameterSetName = "Query")]
        param (
            [parameter(ValueFromPipeline)]
            [Alias("Connstring", "ConnectionString")]
            [DbaInstance[]] $SqlInstance,
            [PsCredential] $SqlCredential,
            [string] $Database,
            [Parameter(Mandatory, ParameterSetName = "Query")]
            [string] $Query,
            [Int32] $QueryTimeout = 600,
            [int] $ConnectTimeout = ([Sqlcollaborative.Dbatools.Connection.ConnectionHost]::SqlConnectionTimeout),
            [Parameter(Mandatory, ParameterSetName = "SMO")]
            [Microsoft.SqlServer.Management.Smo.SqlSmoObject[]]$SqlObject,
            [string] $NetworkProtocol = "sql.connection.protocol",
            [ValidateSet("DataSet", "DataTable", "DataRow", "PSObject", "SingleValue")]
            [string] $As = "DataRow",
            [System.Collections.IDictionary]$SqlParameters,
            [System.Data.CommandType]$CommandType = 'Text',
            [switch] $AppendServerInstance,
            [switch] $MessagesToOutput,
            [parameter(ValueFromPipeline)]
            [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
            [string] $ClientName = "PSFramework - Sql Logging Provider",
            [switch] $EnableException

        )

        begin {
            Write-PSFMessage -Level Verbose -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")"

            $splatInvokeDbaSqlAsync = @{
                As          = $As
                CommandType = $CommandType
            }
            $splatInvokeDbaSqlAsync["SqlParameters"] = $SqlParameters
            $splatInvokeDbaSqlAsync["Query"] = $Query
            $splatInvokeDbaSqlAsync["Verbose"] = $Verbose
        }

        process {
            foreach ($instance in $SqlInstance) {
                try {
                    $connDbaInstanceParams = @{
                        SqlInstance   = $instance
                        SqlCredential = $SqlCredential
                        Database      = $Database
                    }

                    Write-PSFMessage -Level Verbose -Message "Connecting to {0}" -StringValues $instance
                    #$server = Connect-DbaInstance @connDbaInstanceParams
                }
                catch {
                    Stop-PSFFunction -Level Verbose -Message "Failure" -ErrorRecord $_ -Target $instance -Continue
                }

                $conncontext = $instance.ConnectionContext

                try {
                    if ($Database -and $conncontext.DatabaseName -ne $Database) {
                        $conncontext = $instance.ConnectionContext.Copy().GetDatabaseConnection($Database)
                        Invoke-DbaAsync -SQLConnection $conncontext @splatInvokeDbaSqlAsync
                    }
                }
                catch {
                    Stop-Function -Message "[$instance] Failed during execution" -ErrorRecord $_ -Target $instance -Continue
                }
            }
        }
    }
}

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
#endregion Events

# Configuration values for the logging provider
$configuration_Settings = {
    Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.Database' -Value "LoggingDatabase" -Initialize -Validation 'string' -Description "SQL server database."
    Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.DatabaseTable' -Value "LoggingTable" -Initialize -Validation 'string' -Description "SQL server database table."
    Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.Instance' -Value "(localdb)\ProjectsV13" -Initialize -Validation 'string' -Description "SQL server hosting logs."
    Set-PSFConfig -Module PSFramework -Name 'Logging.Sql.LogType' -Value "Message" -Initialize -Validation 'string' -Description "Log type we will log information to."
}

# Registered parameters for the logging provider.
# ConfigurationDefaultValues are used for all instances of the sql log provider
$paramRegisterPSFSqlProvider = @{
    Name                       = "sql"
    Version2                   = $true
    ConfigurationRoot          = 'PSFramework.Logging.Sql'
    InstanceProperties         = 'Database', 'DatabaseTable', 'Instance', 'LogType'
    MessageEvent               = $message_Event
    BeginEvent                 = $begin_event
    ConfigurationSettings      = $configuration_Settings
    FunctionDefinitions        = $functionDefinitions
    ConfigurationDefaultValues = @{
        LogType = 'Message'
    }
}

# Register the Azure logging provider
Register-PSFLoggingProvider @paramRegisterPSFSqlProvider