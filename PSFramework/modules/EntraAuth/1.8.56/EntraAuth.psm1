$script:ModuleRoot = $PSScriptRoot

class FederationProvider {
	[string]$Name
	[string]$Description
	[int]$Priority
	[scriptblock]$Test
	[scriptblock]$Code
	[string]$Assertion
	[string]$Type = 'Custom'

	[string]ToString() {
		return $this.Name
	}
}

enum Environment {
	Global = 1
	USGov = 2
	USGovDOD = 3
	China = 4
}

class FilterBuilder {
	[System.Collections.ArrayList]$Entries = @()
	[System.Collections.ArrayList]$CustomFilter = @()
	
	[ValidateSet('AND','OR')][string]$Logic = 'AND'

	FilterBuilder()	{ }
	FilterBuilder([string]$Logic) {
		$this.Logic = $Logic
	}

	[void]Add([string]$Property, [string]$Operator, $Value) {
		$this.Add($Property, $Operator, $Value, $false)
	}
	[void]Add([string]$Property, [string]$Operator, $Value, [bool]$NoQuotes) {
		$null = $this.Entries.Add(
			@{
				Property = $Property
				Operator = $Operator
				Value    = $Value
				NoQuotes = $NoQuotes
			}
		)
	}
	[void]Add([string]$CustomFilter) {
		$null = $this.Entries.Add($CustomFilter)
	}
	[void]Add([FilterBuilder]$NestedFilter) {
		$null = $this.Entries.Add($NestedFilter)
	}

	[int]Count() {
		$myCount = $this.Entries.Count
		if ($this.CustomFilter) { $myCount += $this.CustomFilter.Count }
		return $myCount
	}
	[string]GetHelp() {
		return @'
OData Filter Builder Guidance

This tool _mostly_ maps / implements the OData filter system, as adapted by the Microsoft Graph API.
It may be relevant to any other API supporting OData filters, but that's what it was built for.

Filter Docs:
https://learn.microsoft.com/en-us/graph/filter-query-parameter

Adding Filter Conditions:
There are two ways to provide filter conditions:

A) .Add(property, operator, value)
The .Add method adds individual filter clauses, simple comparisons or some special behaviors.
For these special rules, see below.
But any operator that has a simple "<property> <operator> <value>" from this list should be valid:
https://learn.microsoft.com/en-us/graph/filter-query-parameter?tabs=http#operators-and-functions-supported-in-filter-expressions
Strings need not be provided in quotes.

B) .Add(customFilter)
Specifying a single string allows providing custom filter terms/expressions.
This can be any valid fragment of OData filter, giving you greater control ... but requires you to write the filter yourself.

All conditions from A) and B) are finally combined with an AND condition.


Special Rules:

eq
The "eq" Operator is converted into a 'startswith' or 'endswith' operator, depending on wildcard use.

leq
The "leq" Operator is not an actual OData operator, but was added by this tool.
It means "Literal Equals" and is converted into an "eq" operator, but without automatic conversion to 'startswith' or 'endswith'.

any
The "any" Operator is the OData equivalent to the PowerShell -contains.

none
The "none" fake-Operator is the OData equivalent to the PowerShell -notcontains.
It translates into an OData all(...) logic with the "ne" operator applied.
'@
	}
	[string]Get() {
		$segments = :entries foreach ($entry in $this.Entries) {
			# Nested Filters
			if ($entry -is [FilterBuilder]) {
				'(' + $entry.Get() + ')'
				continue
			}
			# Custom Filters
			if ($entry -is [string]) {
				'(' + $entry + ')'
				continue
			}


			$quotes = "'"
			if ($entry.NoQuotes) { $quotes = "" }

			$valueString = $entry.Value -as [string]
			if ($null -eq $entry.Value) { $valueString = "null" }
			if (
				$entry.Value -is [string] -or
				$entry.Value -is [guid]
			) {
				$valueString = "$($quotes)$($entry.Value)$($quotes)"
			}
			if ($entry.Value -is [DateTime]) {
				$valueString = $entry.Value.ToString('u') -replace ' ', 'T'
			}

			switch ($entry.Operator) {
				'eq' {
					# Case: eq with Wildcard
					if ($entry.Value -match '\*$' -and $entry.Operator -eq 'eq') {
						"startswith($($entry.Property), $($quotes)$($entry.Value.TrimEnd('*'))$($quotes))"
						continue entries
					}
					if ($entry.Value -match '^\*' -and $entry.Operator -eq 'eq') {
						"endswith($($entry.Property), $($quotes)$($entry.Value.TrimStart('*'))$($quotes))"
						continue entries
					}
					'{0} eq {1}' -f $entry.Property, $valueString
				}
				'leq' {
					'{0} eq {1}' -f $entry.Property, $valueString
				}
				'in' {
					'{0} in ({1})' -f $entry.Property, (@($entry.Value).ForEach{ "$($quotes)$_$($quotes)" } -join ', ')
				}
				'any' {
					'{0}/any(x:x eq {1})' -f $entry.Property, $valueString
				}
				'none' {
					'{0}/all(x:x ne {1})' -f $entry.Property, $valueString
				}
				default {
					'{0} {1} {2}' -f $entry.Property, $entry.Operator, $valueString
				}
			}
		}
		if ($this.CustomFilter) {
			if ($segments) { $segments = @($segments) + $this.CustomFilter }
			else { $segments = $this.CustomFilter }
		}

		if ($this.Logic -eq 'OR') { return $segments -join ' or ' }
		return $segments -join ' and '
	}
	[hashtable]GetHeader() {
		return @{ '$filter' = $this.Get() }
	}
}

class ServiceSelector {
	[hashtable]$DefaultServices = @{ }

	ServiceSelector([Hashtable]$Services) {
		$this.DefaultServices = $Services
	}

	[string]GetService([hashtable]$ServiceMap, [string]$Name) {
		if ($ServiceMap[$Name]) { return $ServiceMap[$Name] }

		return $this.DefaultServices[$Name]
	}
	[hashtable]GetServiceMap([hashtable]$ServiceMap) {
		$map = $this.DefaultServices.Clone()
		if ($ServiceMap) {
			foreach ($pair in $ServiceMap.GetEnumerator()) {
				$map[$pair.Key] = $pair.Value
			}
		}
		return $map
	}
}

class EntraToken {
	#region Token Data
	[string]$AccessToken
	[System.DateTime]$ValidAfter
	[System.DateTime]$ValidUntil
	[string[]]$Scopes
	[string]$RefreshToken
	[string]$Audience
	[string]$Issuer
	[PSObject]$TokenData
	#endregion Token Data
	
	#region Connection Data
	[string]$Service
	[string]$Type
	[string]$ClientID
	[string]$TenantID
	[string]$ServiceUrl
	[string]$AuthenticationUrl
	[Hashtable]$Header = @{}
	[Hashtable]$Query = @{}
	[bool]$RawOnly
	
	[string]$IdentityID
	[string]$IdentityType

	# Workflow: Browser
	[string]$RedirectUri
	
	# Workflow: Client Secret
	[System.Security.SecureString]$ClientSecret
	
	# Workflow: Certificate
	[System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate

	# Workflow: Username & Password
	[PSCredential]$Credential

	# Workflow: Key Vault
	[string]$VaultName
	[string]$SecretName

	# Workflow: Az.Accounts
	[string]$ShowDialog

	# Workflow: Federated
	[FederationProvider]$FederationProvider

	# Workflow: Custom Token
	[scriptblock]$HeaderCode
	[hashtable]$Data = @{}

	#endregion Connection Data
	
	#region Constructors
	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [Securestring]$ClientSecret, [string]$ServiceUrl, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ClientSecret = $ClientSecret
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = 'ClientSecret'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [FederationProvider]$Provider, [string]$ServiceUrl, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.FederationProvider = $Provider
		$this.Type = 'Federated'
	}
	
	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate, [string]$ServiceUrl, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.Certificate = $Certificate
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = 'Certificate'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [pscredential]$Credential, [string]$ServiceUrl, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.Credential = $Credential
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = 'UsernamePassword'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [string]$ServiceUrl, [bool]$IsDeviceCode, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		if ($IsDeviceCode) { $this.Type = 'DeviceCode' }
		else { $this.Type = 'Browser' }
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [string]$ServiceUrl, [string]$VaultName, [string]$SecretName, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ServiceUrl = $ServiceUrl
		$this.VaultName = $VaultName
		$this.SecretName = $SecretName
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = 'KeyVault'
	}

	EntraToken([string]$Service, [string]$ServiceUrl, [string]$IdentityID, [string]$IdentityType) {
		$this.Service = $Service
		$this.ServiceUrl = $ServiceUrl
		$this.Type = 'Identity'

		if ($IdentityID) {
			$this.IdentityID = $IdentityID
			$this.IdentityType = $IdentityType
		}
	}

	EntraToken([string]$Service, [string]$ServiceUrl, [string]$ShowDialog) {
		$this.Service = $Service
		$this.ServiceUrl = $ServiceUrl
		$this.ShowDialog = $ShowDialog
		$this.Type = 'AzAccount'
	}
	
	# Empty Constructor for Import-EntraToken
	EntraToken() {}
	#endregion Constructors

	[void]SetTokenMetadata([PSObject] $AuthToken) {
		$this.AccessToken = $AuthToken.AccessToken
		$this.ValidAfter = $AuthToken.ValidAfter
		$this.ValidUntil = $AuthToken.ValidUntil
		$this.Scopes = $AuthToken.Scopes
		if ($AuthToken.RefreshToken) { $this.RefreshToken = $AuthToken.RefreshToken }

		$tokenPayload = $AuthToken.AccessToken.Split(".")[1].Replace('-', '+').Replace('_', '/')
		while ($tokenPayload.Length % 4) { $tokenPayload += "=" }
		$bytes = [System.Convert]::FromBase64String($tokenPayload)
		$localData = [System.Text.Encoding]::ASCII.GetString($bytes) | ConvertFrom-Json
		
		if ($localData.roles) { $this.Scopes = $localData.roles }
		elseif ($localData.scp) { $this.Scopes = $localData.scp -split " " }

		$this.Audience = $localData.aud
		$this.Issuer = $localData.iss
		$this.TokenData = $localData
		$this.TenantID = $localData.tid
	}

	[hashtable]GetHeader() {
		if ($this.HeaderCode) {
			$newHeader = $this.Header.Clone()
			$results = @(& $this.HeaderCode $this)[0]
			foreach ($pair in $results.GetEnumerator()) {
				$newHeader[$pair.Key] = $pair.Value
			}
			return $newHeader
		}

		if ($this.ValidUntil -lt (Get-Date).AddMinutes(5)) {
			$this.RenewToken()
		}

		$currentHeader = @{}
		if ($this.Header.Count -gt 0) {
			$currentHeader = $this.Header.Clone()
		}
		$currentHeader.Authorization = "Bearer $($this.AccessToken)"

		return $currentHeader
	}

	[void]RenewToken() {
		$defaultParam = @{
			TenantID         = $this.TenantID
			ClientID         = $this.ClientID
			Resource         = $this.Audience
			AuthenticationUrl = $this.AuthenticationUrl
		}
		switch ($this.Type) {
			Certificate {
				$result = Connect-ServiceCertificate @defaultParam -Certificate $this.Certificate
				$this.SetTokenMetadata($result)
			}
			ClientSecret {
				$result = Connect-ServiceClientSecret @defaultParam -ClientSecret $this.ClientSecret
				$this.SetTokenMetadata($result)
			}
			UsernamePassword {
				$result = Connect-ServicePassword @defaultParam -Credential $this.Credential
				$this.SetTokenMetadata($result)
			}
			DeviceCode {
				if ($this.RefreshToken) {
					Connect-ServiceRefreshToken -Token $this
					return
				}

				$result = Connect-ServiceDeviceCode @defaultParam
				$this.SetTokenMetadata($result)
			}
			Browser {
				if ($this.RefreshToken) {
					Connect-ServiceRefreshToken -Token $this
					return
				}

				$result = Connect-ServiceBrowser @defaultParam -SelectAccount -RedirectUri $this.RedirectUri
				$this.SetTokenMetadata($result)
			}
			Refresh {
				Connect-ServiceRefreshToken -Token $this
			}
			KeyVault {
				$secret = Get-VaultSecret -VaultName $this.VaultName -SecretName $this.SecretName
				$result = switch ($secret.Type) {
					Certificate { Connect-ServiceCertificate @defaultParam -Certificate $secret.Certificate }
					ClientSecret { Connect-ServiceClientSecret @defaultParam -ClientSecret $secret.ClientSecret }
				}
				$this.SetTokenMetadata($result)
			}
			Identity {
				$result = Connect-ServiceIdentity -Resource $this.Audience -IdentityID $this.IdentityID -IdentityType $this.IdentityType
				$this.SetTokenMetadata($result)
			}
			AzAccount {
				$result = Connect-ServiceAzure -Resource $this.Audience -ShowDialog $this.ShowDialog
				$this.SetTokenMetadata($result)
			}
			Federated {
				$result, $provider = Connect-ServiceFederated @defaultParam -Provider $this.FederationProvider.Name -Assertion $this.FederationProvider.Assertion
				$this.SetTokenMetadata($result)
			}
		}
	}
}

function Connect-ServiceAzure {
	<#
	.SYNOPSIS
		Authenticates using the established session from Az.Accounts.
	
	.DESCRIPTION
		Authenticates using the established session from Az.Accounts.
		This limits the scopes available to what is configured on the Az Application, but makes it easy to authenticate without active interaction.

		Pretty useful for authenticating to custom apps that do not actually implement scopes.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.
	
	.PARAMETER ShowDialog
		Whether to show a dialog in case of interaction being needed.
		Defaults to: auto
	
	.EXAMPLE
		PS C:\> Connect-ServiceAzure -Resource 'https://graph.microsoft.com'
		
		Connect to graph using the existing az.accounts session.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[ValidateSet('Auto', 'Always', 'Never')]
		[string]
		$ShowDialog = 'Auto'
	)
	process {
		try { $azContext = Get-AzContext -ErrorAction Stop }
		catch { Invoke-TerminatingException -Cmdlet $PSCmdlet -Message 'Error accessing azure context. Ensure the module "Az.Accounts" is installed and you have connected via "Connect-AzAccount"!' -ErrorRecord $_ }
	
		try {
			$result = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
				$azContext.Account,
				$azContext.Environment,
				"$($azContext.Tenant.id)",
				$null,
				$ShowDialog,
				$null,
				$Resource
			)
		
		}
		catch { Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Error retrieving token from Azure for '$Resource': $_" -ErrorRecord $_ }

		$tokenData = Read-TokenData -Token $result.AccessToken

		# A Fake AuthResponse result - Should keep the same layout as the result of Read-AuthResponse
		[PSCustomObject]@{
			AccessToken  = $result.AccessToken
			ValidAfter   = Get-Date
			ValidUntil   = $result.ExpiresOn.LocalDateTime
			Scopes       = $tokenData.scp -split ' '
			RefreshToken = $null

			# For Initial Connect Metadata
			ClientID = $tokenData.appid
			TenantID = $tokenData.tid
		}
	}
}

function Connect-ServiceBrowser {
	<#
	.SYNOPSIS
		Interactive logon using the Authorization flow and browser. Supports SSO.
	
	.DESCRIPTION
		Interactive logon using the Authorization flow and browser. Supports SSO.

		This flow requires an App Registration configured for the platform "Mobile and desktop applications".
		Its redirect Uri must be "http://localhost"

		On successful authentication
	
	.PARAMETER ClientID
		The ID of the registered app used with this authentication request.
	
	.PARAMETER TenantID
		The ID of the tenant connected to with this authentication request.
	
	.PARAMETER SelectAccount
		Forces account selection on logon.
		As this flow supports single-sign-on, it will otherwise not prompt for anything if already signed in.
		This could be a problem if you want to connect using another (e.g. an admin) account.
	
	.PARAMETER Scopes
        Generally doesn't need to be changed from the default '.default'

	.PARAMETER LocalPort
		The local port that should be redirected to.
		In order to process the authentication response, we need to listen to a local web request on some port.
		Usually needs not be redirected.
		Defaults to: 8080
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.

	.PARAMETER RedirectUri
		The Redirect URI to send with the request.
		May be different from the actual local port you want to listen on (e.g. when redirecting to an alternative name on top of localhost).

	.PARAMETER Browser
		The path to the browser to use for the authentication flow.
		Provide the full path to the executable.
		The browser must accept the url to open as its only parameter.
		Defaults to your default browser.

	.PARAMETER BrowserMode
		How the browser used for authentication is selected.
		Options:
		+ Auto (default): Automatically use the default browser.
		+ PrintLink: The link to open is printed on console and user selects which browser to paste it into (must be used on the same machine)
	
	.PARAMETER NoReconnect
		Disables automatic reconnection.
		By default, this module will automatically try to reaquire a new token before the old one expires.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
	
	.EXAMPLE
		PS C:\> Connect-ServiceBrowser -ClientID '<ClientID>' -TenantID '<TenantID>'
	
		Connects to the specified tenant using the specified client, prompting the user to authorize via Browser.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,

		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,

		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[switch]
		$SelectAccount,

		[AllowEmptyCollection()]
		[string[]]
		$Scopes,

		[int]
		$LocalPort = 8080,

		[AllowEmptyString()]
		[string]
		$RedirectUri,

		[string]
		$Browser,

		[Parameter(ParameterSetName = 'Browser')]
		[ValidateSet('Auto', 'PrintLink')]
		[string]
		$BrowserMode = 'Auto',

		[switch]
		$NoReconnect,

		[Parameter(Mandatory = $true)]
        [string]
		$AuthenticationUrl
	)
	process {
		Add-Type -AssemblyName System.Web
		if (-not $Scopes) { $Scopes = @('.default') }

		$localUri = "http://localhost:$LocalPort"
		if (-not $RedirectUri) { $RedirectUri = $localUri }
		$actualScopes = $Scopes | Resolve-ScopeName -Resource $Resource

		if (-not $NoReconnect) {
			$actualScopes = @($actualScopes) + 'offline_access'
		}

		$uri = "$AuthenticationUrl/$TenantID/oauth2/v2.0/authorize?"
		$state = Get-Random
		$parameters = @{
			client_id     = $ClientID
			response_type = 'code'
			redirect_uri  = $RedirectUri
			response_mode = 'query'
			scope         = $actualScopes -join ' '
			state         = $state
		}
		if ($SelectAccount) {
			$parameters.prompt = 'select_account'
		}

		$paramStrings = foreach ($pair in $parameters.GetEnumerator()) {
			$pair.Key, ([System.Web.HttpUtility]::UrlEncode($pair.Value)) -join '='
		}
		$uriFinal = $uri + ($paramStrings -join '&')
		Write-Verbose "Authorize Uri: $uriFinal"

		#$redirectTo = 'https://raw.githubusercontent.com/FriedrichWeinmann/EntraAuth/master/nothing-to-see-here.txt'
		#$redirectTo = (Join-Path -Path $script:ModuleRoot -ChildPath 'nothing-to-see-here.txt') -replace '\\','/'
		$redirectTo = "http://localhost:$(Get-Random -Minimum 9800 -Maximum 9999)/"
		if ((Get-Random -Minimum 10 -Maximum 99) -eq 66) {
			$redirectTo = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
		}
		
		# Start local server to catch the redirect
		$http = [System.Net.HttpListener]::new()
		$http.Prefixes.Add(("$RedirectUri/" -replace '//$', '/'))
		if ($localUri -ne $RedirectUri) { $http.Prefixes.Add(("$localUri/" -replace '//$', '/')) }
		try { $http.Start() }
		catch { Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Failed to create local http listener on port $LocalPort. Use -LocalPort to select a different port. $_" -Category OpenError }

		switch ($BrowserMode) {
			Auto {
				# Execute in default browser
				if ($Browser) { & $Browser $uriFinal }
				else { Start-Process $uriFinal }
			}
			PrintLink {
				Write-Host @"
Ready to authenticate. Paste the following link into the browser of your choice on the local computer:
$uriFinal
"@
			}
		}

		# Get Result
		$task = $http.GetContextAsync()
		$authorizationCode, $stateReturn, $sessionState = $null
		try {
			while (-not $task.IsCompleted) {
				Start-Sleep -Milliseconds 200
			}
			$http2 = [System.Net.HttpListener]::new()
			$http2.Prefixes.Add($redirectTo)
			$http2.Start()

			$context = $task.Result
			$context.Response.Redirect($redirectTo)
			$context.Response.Close()
			$authorizationCode, $stateReturn, $sessionState = $context.Request.Url.Query -split "&"

			$task2 = $http2.GetContextAsync()
			while (-not $task2.IsCompleted) {
				Start-Sleep -Milliseconds 200
			}
			$context2 = $task2.Result
			$bytes = [System.Text.Encoding]::UTF8.GetBytes('Authentication flow completed, you can close the tab now.')
			$context2.Response.ContentEncoding = [System.Text.Encoding]::UTF8
			$context2.Response.OutputStream.Write($bytes,0,$bytes.Length)
			$context2.Response.Close()
		}
		finally {
			$http.Stop()
			$http.Dispose()
			if ($http2.IsListening) {
				$http2.Stop()
				$http2.Dispose()
			}
		}

		if (-not $stateReturn) {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Authentication failed (see browser for details)" -Category AuthenticationError
		}

		if ($stateReturn -match '^error_description=') {
			$message = $stateReturn -replace '^error_description=' -replace '\+',' '
			$message = [System.Web.HttpUtility]::UrlDecode($message)
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Error processing the request: $message" -Category InvalidOperation
		}

		if ($state -ne $stateReturn.Split("=")[1]) {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Received invalid authentication result. Likely returned from another flow redirecting to the same local port!" -Category InvalidOperation
		}

		$actualAuthorizationCode = $authorizationCode.Split("=")[1]

		$body = @{
			client_id    = $ClientID
			scope        = $actualScopes -join " "
			code         = $actualAuthorizationCode
			redirect_uri = $RedirectUri
			grant_type   = 'authorization_code'
		}
		$uri = "$AuthenticationUrl/$TenantID/oauth2/v2.0/token"
		try { $authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ErrorAction Stop }
		catch {
			if ($_ -notmatch '"error":\s*"invalid_client"') { Invoke-TerminatingException -Cmdlet $PSCmdlet -ErrorRecord $_ }
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "The App Registration $ClientID has not been configured correctly. Ensure you have a 'Mobile and desktop applications' platform with redirect to 'http://localhost' configured (and not a 'Web' Platform). $_" -Category $_.CategoryInfo.Category
		}
		Read-AuthResponse -AuthResponse $authResponse
	}
}

function Connect-ServiceCertificate {
    <#
	.SYNOPSIS
		Connects to AAD using a application ID and a certificate.
	
	.DESCRIPTION
		Connects to AAD using a application ID and a certificate.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.
	
	.PARAMETER Certificate
		The certificate to use for authentication.
	
	.PARAMETER TenantID
		The ID of the tenant/directory to connect to.
	
	.PARAMETER ClientID
		The ID of the registered application used to authenticate as.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
	
	.EXAMPLE
		PS C:\> Connect-ServiceCertificate -Certificate $cert -TenantID $tenantID -ClientID $clientID
	
		Connects to the specified tenant using the specified app & cert.
	
	.LINK
		https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-certificate-credentials
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,
		
        [Parameter(Mandatory = $true)]
        [string]
        $TenantID,
		
        [Parameter(Mandatory = $true)]
        [string]
        $ClientID,

		[Parameter(Mandatory = $true)]
        [string]
		$AuthenticationUrl
    )
	
    #region Build Signature Payload
    $jwtHeader = @{
        alg = "RS256"
        typ = "JWT"
        x5t = [Convert]::ToBase64String($Certificate.GetCertHash()) -replace '\+', '-' -replace '/', '_' -replace '='
    }
    $encodedHeader = $jwtHeader | ConvertTo-Json | ConvertTo-Base64
    $claims = @{
        aud = "$AuthenticationUrl/$TenantID/oauth2/v2.0/token"
        exp = ((Get-Date).AddMinutes(5).ToUniversalTime() - (Get-Date -Date '1970-01-01')).TotalSeconds -as [int]
        iss = $ClientID
        jti = "$(New-Guid)"
        nbf = ((Get-Date).ToUniversalTime() - (Get-Date -Date '1970-01-01')).TotalSeconds -as [int]
        sub = $ClientID
    }
    $encodedClaims = $claims | ConvertTo-Json | ConvertTo-Base64
    $jwtPreliminary = $encodedHeader, $encodedClaims -join "."
    $jwtSigned = ($jwtPreliminary | ConvertTo-SignedString -Certificate $Certificate) -replace '\+', '-' -replace '/', '_' -replace '='
    $jwt = $jwtPreliminary, $jwtSigned -join '.'
    #endregion Build Signature Payload
	
    $body = @{
        client_id             = $ClientID
        client_assertion      = $jwt
        client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        scope                 = '{0}/.default' -f $Resource
        grant_type            = 'client_credentials'
    }
    $header = @{
        Authorization = "Bearer $jwt"
    }
    $uri = "$AuthenticationUrl/$TenantID/oauth2/v2.0/token"
	
    try { $authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body -Headers $header -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop }
    catch { throw }
	
    Read-AuthResponse -AuthResponse $authResponse
}

function Connect-ServiceClientSecret {
    <#
	.SYNOPSIS
		Connets using a client secret.
	
	.DESCRIPTION
		Connets using a client secret.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.
	
	.PARAMETER ClientID
		The ID of the registered app used with this authentication request.
	
	.PARAMETER TenantID
		The ID of the tenant connected to with this authentication request.
	
	.PARAMETER ClientSecret
		The actual secret used for authenticating the request.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
	
	.EXAMPLE
		PS C:\> Connect-ServiceClientSecret -ClientID '<ClientID>' -TenantID '<TenantID>' -ClientSecret $secret -Resource '<Resource>' -AuthenticationUrl 'https://login.microsoftonline.com'
	
		Connects to the specified tenant using the specified client and secret.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
        [string]
        $ClientID,
		
        [Parameter(Mandatory = $true)]
        [string]
        $TenantID,
		
        [Parameter(Mandatory = $true)]
        [securestring]
        $ClientSecret,

		[Parameter(Mandatory = $true)]
        [string]
		$AuthenticationUrl
    )
	
    process {
        $body = @{
            resource      = $Resource
            client_id     = $ClientID
            client_secret = [PSCredential]::new('NoMatter', $ClientSecret).GetNetworkCredential().Password
            grant_type    = 'client_credentials'
        }
        try { $authResponse = Invoke-RestMethod -Method Post -Uri "$AuthenticationUrl/$TenantId/oauth2/token" -Body $body -ErrorAction Stop }
        catch { throw }
		
        Read-AuthResponse -AuthResponse $authResponse
    }
}

function Connect-ServiceDeviceCode {
	<#
	.SYNOPSIS
		Connects to Azure AD using the Device Code authentication workflow.
	
	.DESCRIPTION
		Connects to Azure AD using the Device Code authentication workflow.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.

	.PARAMETER ClientID
		The ID of the registered app used with this authentication request.
	
	.PARAMETER TenantID
		The ID of the tenant connected to with this authentication request.
	
	.PARAMETER Scopes
		The scopes to request.
		Automatically scoped to the service specified via Service Url.
		Defaults to ".Default"

	.PARAMETER NoReconnect
		Disables automatic reconnection.
		By default, this module will automatically try to reaquire a new token before the old one expires.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
	
	.EXAMPLE
		PS C:\> Connect-ServiceDeviceCode -Resource 'https://graph.microsoft.com' -ClientID '<ClientID>' -TenantID '<TenantID>' -AuthenticationUrl 'https://login.microsoftonline.com'
	
		Connects to the specified tenant using the specified client, prompting the user to authorize via Device Code workflow.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,
        
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,
        
		[AllowEmptyCollection()]
		[string[]]
		$Scopes,

		[switch]
		$NoReconnect,

		[Parameter(Mandatory = $true)]
        [string]
		$AuthenticationUrl
	)

	if (-not $Scopes) { $Scopes = @('.default') }
	$actualScopes = $Scopes | Resolve-ScopeName -Resource $Resource

	if (-not $NoReconnect) {
		$actualScopes = @($actualScopes) + 'offline_access'
	}

	try {
		$initialResponse = Invoke-RestMethod -Method POST -Uri "$AuthenticationUrl/$TenantID/oauth2/v2.0/devicecode" -Body @{
			client_id = $ClientID
			scope     = $actualScopes -join " "
		} -ErrorAction Stop
	}
	catch {
		throw
	}

	Write-Host $initialResponse.message

	$paramRetrieve = @{
		Uri         = "$AuthenticationUrl/$TenantID/oauth2/v2.0/token"
		Method      = "POST"
		Body        = @{
			grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
			client_id   = $ClientID
			device_code = $initialResponse.device_code
		}
		ErrorAction = 'Stop'
	}
	$limit = (Get-Date).AddSeconds($initialResponse.expires_in)
	while ($true) {
		if ((Get-Date) -gt $limit) {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Timelimit exceeded, device code authentication failed" -Category AuthenticationError
		}
		Start-Sleep -Seconds $initialResponse.interval
		try { $authResponse = Invoke-RestMethod @paramRetrieve }
		catch {
			if ($_ -match '"error":\s*"authorization_pending"') { continue }
			$PSCmdlet.ThrowTerminatingError($_)
		}
		if ($authResponse) {
			break
		}
	}

	Read-AuthResponse -AuthResponse $authResponse
}

function Connect-ServiceFederated {
	<#
	.SYNOPSIS
		Authenticate using the Federated Credentials flow.
	
	.DESCRIPTION
		Authenticate using the Federated Credentials flow.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.
	
	.PARAMETER ClientID
		The ID of the registered app used with this authentication request.
	
	.PARAMETER TenantID
		The ID of the tenant connected to with this authentication request.
	
	.PARAMETER Provider
		The name of the provider to use.
		Overrides auto-selection if provided.

	.PARAMETER Assertion
		An externally provided assertion from the federated authentication provider.
		This skips the internal assertion resolution process and moves straight to the authentication to Entra

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
	
	.EXAMPLE
		PS C:\> Connect-ServiceFederated -ClientID '<ClientID>' -TenantID '<TenantID>' -Resource '<Resource>' -AuthenticationUrl 'https://login.microsoftonline.com'

		Connects to the specified tenant using the specified client and automatically calculated federated credential.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,
		
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,
		
		[AllowEmptyString()]
		[string]
		$Provider,

		[AllowEmptyString()]
		[string]
		$Assertion,

		[Parameter(Mandatory = $true)]
		[string]
		$AuthenticationUrl
	)
	process {
		$providerObject = $null
		$myAssertion = $Assertion
		if (-not $myAssertion) {
			if ($Provider) { $providerObject = $script:_FederationProviders[$Provider] }
			else { $providerObject = Resolve-EntraFederationProvider }

			if (-not $providerObject) {
				Invoke-TerminatingException -Cmdlet $PSCmdlet -Category AuthenticationError -Message "Unable to find an applicable Federation Provider! Ensure you have a Federation Provider registered and are running in an environment where detection can work."
			}

			try { $myAssertion = & $providerObject.Code }
			catch { Invoke-TerminatingException -Cmdlet $PSCmdlet -ErrorRecord $_ -Message "Failed to access a token from the federated identity provider! $_" }
		}

		$body = @{
			resource              = $Resource
			client_id             = $ClientID
			client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
			client_assertion      = $myAssertion
			grant_type            = 'client_credentials'
		}
		try { $authResponse = Invoke-RestMethod -Method Post -Uri "$AuthenticationUrl/$TenantId/oauth2/token" -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop }
		catch { throw }
		
		Read-AuthResponse -AuthResponse $authResponse
		if ($providerObject) { return $providerObject }
		[FederationProvider]@{
			Assertion = $myAssertion
		}
	}
}

function Connect-ServiceIdentity {
	<#
	.SYNOPSIS
		Connect as the current Managed Identity.

	.DESCRIPTION
		Connect as the current Managed Identity.
		Only works from within the context of a managed environment, such as Azure Functions with enabled MSI.

	.PARAMETER Resource
		The resource to get a token for.

	.PARAMETER IdentityID
		ID of the User-Managed Identity to connect as.

	.PARAMETER IdentityType
		Type of the User-Managed Identity.

	.PARAMETER Cmdlet
		The $PSCmdlet of the calling command.
		If specified, errors are triggered in the caller's context.

	.EXAMPLE
		PS C:\> Connect-ServiceIdentity -Resource 'https://vault.azure.net'

		Connect as the current managed identity, retrieving a token for the Azure Key Vault.

	.LINK
		https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$IdentityID,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$IdentityType,

		$Cmdlet = $PSCmdlet
	)
	process {
		# Logic for Azure VMs
		try {
			$vmMetadata = $null
			$vmMetadata = Invoke-RestMethod -Headers @{Metadata = "true" } -Method GET -NoProxy -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
		}
		catch {
			$vmMetadata = $null
		}
		if ($vmMetadata.compute.azEnvironment -like "*Azure*") {
			Write-Verbose "We are running on an Azure VM. Setting Environment Variables"
			$isAzureVM = $true
			$env:IDENTITY_ENDPOINT = "http://169.254.169.254/metadata/identity/oauth2/token"
			$env:IDENTITY_API_VERSION = "2018-02-01"
		}

		if ((-not $env:IDENTITY_ENDPOINT) -or (-not $env:IDENTITY_HEADER)) {
			Invoke-TerminatingException -Cmdlet $Cmdlet -Message "Cannot identify a Managed Identity. MSI logon not possible!" -Category ConnectionError
		}

		$apiVersion = $env:IDENTITY_API_VERSION
		if (-not $apiVersion) { $apiVersion = '2019-08-01' }

		$url = "$($env:IDENTITY_ENDPOINT)?resource=$Resource&api-version=$apiVersion"
		if ($IdentityID) {
			$labels = @{
				ClientID    = 'client_id'
				ResourceID  = 'mi_res_id'
				PrincipalID = 'principal_id'
			}
			$url = $url + "&$($labels[$IdentityType])=$($IdentityID)"
		}

		try {
			Write-Verbose "$url"
			if ($isAzureVM) {
				$headers = @{Metadata = 'true' }
			}
			else {
				$headers = @{'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER }
			}
			$authResponse = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
		}
		catch {
			Invoke-TerminatingException -Cmdlet $Cmdlet -Message "Failed to connect via Managed Identity: $_" -ErrorRecord $_
		}

		Read-AuthResponse -AuthResponse $authResponse
	}
}

function Connect-ServicePassword {
	<#
    .SYNOPSIS
        Connect to graph using username and password.
    
    .DESCRIPTION
        Connect to graph using username and password.
        This logs into graph as a user, not as an application.
        Only cloud-only accounts can be used for this workflow.
        Consent to scopes must be granted before using them, as this command cannot show the consent prompt.
	
	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.

    .PARAMETER Credential
        Credentials of the user to connect as.
        
    .PARAMETER TenantID
        The Guid of the tenant to connect to.

    .PARAMETER ClientID
        The ClientID / ApplicationID of the application to use.
    
    .PARAMETER Scopes
        The permission scopes to request.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
    
    .EXAMPLE
        PS C:\> Connect-ServicePassword -Credential max@contoso.com -ClientID $client -TenantID $tenant -Scopes 'user.read','user.readbasic.all' -Resource 'https://graph.microsoft.com' -AuthenticationUrl 'https://login.microsoftonline.com'
        
        Connect as max@contoso.com with the rights to read user information.
    #>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$Credential,
        
		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,
        
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,
        
		[string[]]
		$Scopes = '.default',

		[Parameter(Mandatory = $true)]
        [string]
		$AuthenticationUrl
	)

	$actualScopes = $Scopes | Resolve-ScopeName -Resource $Resource
    
	$request = @{
		client_id  = $ClientID
		scope      = $actualScopes -join " "
		username   = $Credential.UserName
		password   = $Credential.GetNetworkCredential().Password
		grant_type = 'password'
	}
    
	try { $authResponse = Invoke-RestMethod -Method POST -Uri "$AuthenticationUrl/$TenantID/oauth2/v2.0/token" -Body $request -ErrorAction Stop }
	catch { throw }
	
	Read-AuthResponse -AuthResponse $authResponse
}

function Connect-ServiceRefreshToken {
	<#
	.SYNOPSIS
		Connect with the refresh token provided previously.
	
	.DESCRIPTION
		Connect with the refresh token provided previously.
		Used mostly for delegate authentication flows to avoid interactivity.

		Can also be resolved to from the outside, when trying to get multiple tokens with a single delegate flow.

	.PARAMETER Token
		The EntraToken object with the refresh token to use.
		The token is then refreshed in-place with no output provided.

	.PARAMETER RefreshToken
		The RefreshToken to use for authenticating.

	.PARAMETER TenantID
		ID of the tenant to connect to.

	.PARAMETER ClientID
		ID of the application to connect as.

	.PARAMETER Resource
		Resource we want the scopes for.

	.PARAMETER Scopes
		Scopes we want to use.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
	
	.EXAMPLE
		PS C:\> Connect-ServiceRefreshToken -Token $token
		
		Connect with the refresh token provided previously.

	.EXAMPLE
        PS C:\> Connect-ServiceRefreshToken -RefreshToken $refreshToken -TenantID '<TenantID>' -ClientID '<ClientID>' -Resource 'https://graph.microsoft.com' -Scopes @('User.Read', 'Mail.Read') -AuthenticationUrl 'https://login.microsoftonline.com'
        
        Connect using specific refresh token details with custom scopes for Microsoft Graph.
		
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Token')]
		$Token,

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[string]
		$RefreshToken,

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[string]
		$TenantID,

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[string]
		$ClientID,

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
		[string]
		$Resource,

		[Parameter(ParameterSetName = 'Details')]
		[string[]]
		$Scopes = '.default',

		[Parameter(Mandatory = $true, ParameterSetName = 'Details')]
        [string]
		$AuthenticationUrl
	)
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'Token' {
				if (-not $Token.RefreshToken) {
					throw "Failed to refresh token: No refresh token found!"
				}
		
				$effectiveScopes = $Token.Scopes
		
				$body = @{
					client_id = $Token.ClientID
					scope = @($effectiveScopes).ForEach{"$($Token.Audience)/$($_)"} -join " "
					refresh_token = $Token.RefreshToken
					grant_type = 'refresh_token'
				}
				$uri = "$($Token.AuthenticationUrl)/$($Token.TenantID)/oauth2/v2.0/token"
				$authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body
				$Token.SetTokenMetadata((Read-AuthResponse -AuthResponse $authResponse))
			}
			'Details' {
				$effectiveScopes = foreach ($scope in $Scopes) {
					if ($scope -like "$Resource*") { $scope }
					else { "$Resource/$scope" }
				}

				$body = @{
					client_id = $ClientID
					scope = $effectiveScopes -join " "
					refresh_token = $RefreshToken
					grant_type = 'refresh_token'
				}
				$uri = "$($AuthenticationUrl)/$($TenantID)/oauth2/v2.0/token"
				$authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body
				Read-AuthResponse -AuthResponse $authResponse
			}
		}
	}
}

function Get-VaultSecret {
	<#
	.SYNOPSIS
		Retrieve a secret from Azure Key Vault.
	
	.DESCRIPTION
		Retrieve a secret from Azure Key Vault.
		Works for both certificates and secrets.

		Requires one of ...
		- An established connection with the AzureKeyVault service.
		- An established AZ session via Az.Accounts with the Az.KeyVault module present.
	
	.PARAMETER VaultName
		Name of the Vault to query.
	
	.PARAMETER SecretName
		Name of the Secret to retrieve.
	
	.PARAMETER Cmdlet
		The $PSCmdlet object of the caller, enabling errors to happen within the scope of the caller.
		Defaults to the current command's $PSCmdlet
	
	.EXAMPLE
		PS C:\> Get-VaultSecret -VaultName myvault -SecretName mysecret
		
		Retrieves the latest enabled version of mysecret from myvault
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$VaultName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$SecretName,

		$Cmdlet = $PSCmdlet
	)

	process {
		#region Via EntraAuth
		if (Get-EntraToken -Service AzureKeyVault) {
			try {
				$secretVersion = Invoke-EntraRequest -Service AzureKeyVault -Path "secrets/$SecretName/versions" -VaultName $VaultName -ErrorAction Stop | Where-Object {
					$_.attributes.enabled
				} | Sort-Object { $_.attributes.created } -Descending | Select-Object -First 1

				if (-not $secretVersion) {
					Invoke-TerminatingException -Cmdlet $Cmdlet -ErrorRecord $_ -Message "Secret '$SecretName' does not exist in vault '$VaultName'! $_"
				}
				$secretData = Invoke-EntraRequest -Service AzureKeyVault -Path $secretVersion.id -VaultName $VaultName -ErrorAction Stop
			}
			catch {
				Invoke-TerminatingException -Cmdlet $Cmdlet -ErrorRecord $_ -Message "Failed to retrieve secret '$SecretName' from '$VaultName'! $_"
			}

			if ($secretVersion.contentType) {
				$secretBytes = [convert]::FromBase64String($secretData)
				$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($secretBytes)
				[PSCustomObject]@{
					Type         = 'Certificate'
					Certificate  = $certificate
					ClientSecret = $null
				}
			}
			else {
				[PSCustomObject]@{
					Type         = 'ClientSecret'
					Certificate  = $null
					ClientSecret = $secretData | ConvertTo-SecureString -AsPlainText -Force
				}
			}

			return
		}
		#endregion Via EntraAuth

		#region Via Az.KeyVault
		if ((Get-Module Az.Accounts -ListAvailable) -and (Get-AzContext) -and (Get-Module Az.KeyVault -ListAvailable)) {
			try { $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName }
			catch { Invoke-TerminatingException -Cmdlet $Cmdlet -ErrorRecord $_ -Message "Error accessing the secret '$Secretname' from Vault '$VaultName'. $_" }

			$type = 'Certificate'
			if (-not $secret.ContentType) { $type = 'ClientSecret' }

			$certificate = $null
			$clientSecret = $secret.SecretValue

			if ($type -eq 'Certificate') {
				$certString = [PSCredential]::New("irrelevant", $secret.SecretValue).GetNetworkCredential().Password
				$bytes = [convert]::FromBase64String($certString)
				$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($bytes)
				$clientSecret = $null
			}
			
			[PSCustomObject]@{
				Type         = $type
				Certificate  = $certificate
				ClientSecret = $clientSecret
			}

			return
		}
		#endregion Via Az.KeyVault

		Invoke-TerminatingException -Cmdlet $Cmdlet -Message "Not connected to azure yet! Either use 'Connect-EntraService -Service AzureKeyVault' or 'Connect-AzAccount' before trying to connect via KeyVault!" -Category ConnectionError
	}
}

function Read-AuthResponse {
	<#
	.SYNOPSIS
		Produces a standard output representation of the authentication response received.
	
	.DESCRIPTION
		Produces a standard output representation of the authentication response received.
		This streamlines the token processing and simplifies the connection code.
	
	.PARAMETER AuthResponse
		The authentication response received.
	
	.EXAMPLE
		PS C:\> Read-AuthResponse -AuthResponse $authResponse

		Reads the authentication details received.
	#>
	[CmdletBinding()]
	param (
		$AuthResponse
	)
	process {
		if ($AuthResponse.expires_in) {
			$after = (Get-Date).AddMinutes(-5)
			$until = (Get-Date).AddSeconds($AuthResponse.expires_in)
		}
		else {
			if ($AuthResponse.not_before)  { $after = (Get-Date -Date '1970-01-01').AddSeconds($AuthResponse.not_before).ToLocalTime() }
			else { $after = Get-Date }
			$until = (Get-Date -Date '1970-01-01').AddSeconds($AuthResponse.expires_on).ToLocalTime()
		}
		$scopes = @()
		if ($AuthResponse.scope) { $scopes = $authResponse.scope -split " " }

		# If updating this layout, also update in Connect-ServiceAzure, which fakes this object
		[pscustomobject]@{
			AccessToken  = $AuthResponse.access_token
			ValidAfter   = $after
			ValidUntil   = $until
			Scopes       = $scopes
			RefreshToken = $AuthResponse.refresh_token
		}
	}
}

function ConvertTo-Base64 {
<#
	.SYNOPSIS
		Converts the input-string to its base 64 encoded string form.
	
	.DESCRIPTION
		Converts the input-string to its base 64 encoded string form.
	
	.PARAMETER Text
		The text to convert.
	
	.PARAMETER Encoding
		The encoding of the input text.
		Used to correctly translate the input string into bytes before converting those to base 64.
		Defaults to UTF8
	
	.EXAMPLE
		PS C:\> Get-Content .\code.ps1 -Raw | ConvertTo-Base64
	
		Reads the input file and converts its content into base64.
#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]]
		$Text,
		
		[System.Text.Encoding]
		$Encoding = [System.Text.Encoding]::UTF8
	)
	
	process {
		foreach ($entry in $Text) {
			$bytes = $Encoding.GetBytes($entry)
			[Convert]::ToBase64String($bytes)
		}
	}
}

function ConvertTo-Hashtable {
	<#
	.SYNOPSIS
		Converts input objects into hashtables.
	
	.DESCRIPTION
		Converts input objects into hashtables.
		Allows explicitly including some properties only and remapping key-names as required.
	
	.PARAMETER Include
		Only select the specified properties.
	
	.PARAMETER Mapping
		Remap hashtable/property keys.
		This allows you to rename parameters before passing them through to other commands.
		Example:
		@{ Select = '$select' }
		This will map the "Select"-property/key on the input object to be '$select' on the output item.
	
	.PARAMETER InputObject
		The object to convert.
	
	.EXAMPLE
		PS C:\> $__body = $PSBoundParameters | ConvertTo-Hashtable -Include Name, UserID -Mapping $__mapping

		Converts the object $PSBoundParameters into a hashtable, including the keys "Name" and "UserID" and remapping them as specified in $__mapping
	#>
	[OutputType([hashtable])]
    [CmdletBinding()]
    param (
        [AllowEmptyCollection()]
        [string[]]
        $Include,

        [Hashtable]
        $Mapping = @{ },

        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    process {
        $result = @{ }
        if ($InputObject -is [System.Collections.IDictionary]) {
            foreach ($pair in $InputObject.GetEnumerator()) {
                if ($pair.Key -notin $Include) { continue }
                if ($Mapping[$pair.Key]) { $result[$Mapping[$pair.Key]] = $pair.Value }
                else { $result[$pair.Key] = $pair.Value }
            }
        }
        else {
            foreach ($property in $InputObject.PSObject.Properties) {
                if ($property.Name -notin $Include) { continue }
                if ($Mapping[$property.Name]) { $result[$Mapping[$property.Name]] = $property.Value }
                else { $result[$property.Name] = $property.Value }
            }
        }
        $result
    }
}

function ConvertTo-QueryString {
	<#
    .SYNOPSIS
        Convert conditions in a hashtable to a Query string to append to a webrequest.
    
    .DESCRIPTION
        Convert conditions in a hashtable to a Query string to append to a webrequest.
    
    .PARAMETER QueryHash
        Hashtable of query modifiers - usually filter conditions - to include in a web request.

	.PARAMETER DefaultQuery
		Default query parameters defined in the service configuration.
		Default query settings are overriden by explicit query parameters.
    
    .EXAMPLE
        PS C:\> ConvertTo-QueryString -QueryHash $Query

        Converts the conditions in the specified hashtable to a Query string to append to a webrequest.
    #>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[Hashtable]
		$QueryHash,

		[AllowNull()]
		[hashtable]
		$DefaultQuery
	)

	process {
		if ($DefaultQuery) { $query = $DefaultQuery.Clone() }
		else { $query = @{} }

		foreach ($key in $QueryHash.Keys) {
			$query[$key] = $QueryHash[$key]
		}
		if ($query.Count -lt 1) { return '' }


		$elements = foreach ($pair in $query.GetEnumerator()) {
			'{0}={1}' -f $pair.Name, ($pair.Value -join ",")
		}
		'?{0}' -f ($elements -join '&')
	}
}

function ConvertTo-SignedString {
<#
	.SYNOPSIS
		Signs input string with the offered certificate.
	
	.DESCRIPTION
		Signs input string with the offered certificate.
	
	.PARAMETER Text
		The text to sign.
	
	.PARAMETER Certificate
		The certificate to sign with.
		The Private Key must be available.
	
	.PARAMETER Padding
		What RSA Signature padding to use.
		Defaults to Pkcs1
	
	.PARAMETER Algorithm
		What algorithm to use for signing.
		Defaults to SHA256
	
	.PARAMETER Encoding
		The encoding to use for transforming the text to bytes before signing it.
		Defaults to UTF8
	
	.EXAMPLE
		PS C:\> ConvertTo-SignedString -Text $token
	
		Signs the specified token
#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]]
		$Text,
		
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate,
		
		[Security.Cryptography.RSASignaturePadding]
		$Padding = [Security.Cryptography.RSASignaturePadding]::Pkcs1,
		
		[Security.Cryptography.HashAlgorithmName]
		$Algorithm = [Security.Cryptography.HashAlgorithmName]::SHA256,
		
		[System.Text.Encoding]
		$Encoding = [System.Text.Encoding]::UTF8
	)
	
	begin {
		$privateKey = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
	}
	process {
		foreach ($entry in $Text) {
			$inBytes = $Encoding.GetBytes($entry)
			$outBytes = $privateKey.SignData($inBytes, $Algorithm, $Padding)
			[convert]::ToBase64String($outBytes)
		}
	}
}

function Invoke-TerminatingException {
	<#
	.SYNOPSIS
		Throw a terminating exception in the context of the caller.
	
	.DESCRIPTION
		Throw a terminating exception in the context of the caller.
		Masks the actual code location from the end user in how the message will be displayed.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command.
	
	.PARAMETER Message
		The message to show the user.
	
	.PARAMETER Exception
		A nested exception to include in the exception object.
	
	.PARAMETER Category
		The category of the error.
	
	.PARAMETER ErrorRecord
		A full error record that was caught by the caller.
		Use this when you want to rethrow an existing error.
	
	.EXAMPLE
		PS C:\> Invoke-TerminatingException -Cmdlet $PSCmdlet -Message 'Unknown calling module'
	
		Terminates the calling command, citing an unknown caller.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$Cmdlet,
		
		[string]
		$Message,
		
		[System.Exception]
		$Exception,
		
		[System.Management.Automation.ErrorCategory]
		$Category = [System.Management.Automation.ErrorCategory]::NotSpecified,
		
		[System.Management.Automation.ErrorRecord]
		$ErrorRecord
	)
	
	process {
		if ($ErrorRecord -and -not $Message) {
			$Cmdlet.ThrowTerminatingError($ErrorRecord)
		}
		
		$exceptionType = switch ($Category) {
			default { [System.Exception] }
			'InvalidArgument' { [System.ArgumentException] }
			'InvalidData' { [System.IO.InvalidDataException] }
			'AuthenticationError' { [System.Security.Authentication.AuthenticationException] }
			'InvalidOperation' { [System.InvalidOperationException] }
		}
		
		
		if ($Exception) { $newException = $Exception.GetType()::new($Message, $Exception) }
		elseif ($ErrorRecord) {
			try { $newException = $ErrorRecord.Exception.GetType()::new($Message, $ErrorRecord.Exception) }
			catch { $newException = [System.Exception]::new($Message, $ErrorRecord.Exception) }
		}
		else { $newException = $exceptionType::new($Message) }
		$record = [System.Management.Automation.ErrorRecord]::new($newException, (Get-PSCallStack)[1].FunctionName, $Category, $Target)
		$Cmdlet.ThrowTerminatingError($record)
	}
}

function Read-TokenData {
	<#
	.SYNOPSIS
		Reads a JWT token and converts it into a custom object showing its properties.
	
	.DESCRIPTION
		Reads a JWT token and converts it into a custom object showing its properties.
	
	.PARAMETER Token
		The JWT Token to parse
	
	.EXAMPLE
		PS C:\> Read-TokenData -Token $authresponse.access_token
		
		Reads the settings on the returned access token.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
        [string]
        $Token
	)
	process {
		$tokenPayload = $Token.Split(".")[1].Replace('-', '+').Replace('_', '/')
		# Pad with "=" until string length modulus 4 reaches 0
		while ($tokenPayload.Length % 4) { $tokenPayload += "=" }
		$bytes = [System.Convert]::FromBase64String($tokenPayload)
		[System.Text.Encoding]::ASCII.GetString($bytes) | ConvertFrom-Json
	}
}

function Resolve-Certificate {
	<#
	.SYNOPSIS
		Helper function to resolve certificate input.
	
	.DESCRIPTION
		Helper function to resolve certificate input.
		This function expects the full $PSBoundParameters from the calling command and will (in this order) look for these parameter names:

		+ Certificate: A full X509Certificate2 object with private key
		+ CertificateThumbprint: The thumbprint of a certificate to use. Will look first in the user store, then the machine store for it.
		+ CertificateName: The subject of the certificate to look for. Will look first in the user store, then the machine store for it. Will select the certificate with the longest expiration period.
		+ CertificatePath: Path to a PFX file to load. Also expects a CertificatePassword parameter to unlock the file.
	
	.PARAMETER BoundParameters
		The $PSBoundParameter variable of the caller to simplify passthrough.
		See Description for more details on what the command expects,
	
	.EXAMPLE
		PS C:\> $certificateObject = Resolve-Certificate -BoundParameters $PSBoundParameters

		Resolves the certificate based on the parameters provided to the calling command.
	#>
	[OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
	[CmdletBinding()]
	param (
		$BoundParameters
	)
	
	if ($BoundParameters.Certificate) { return $BoundParameters.Certificate }
	if ($BoundParameters.CertificateThumbprint) {
		if (Test-Path -Path "cert:\CurrentUser\My\$($BoundParameters.CertificateThumbprint)") {
			return Get-Item "cert:\CurrentUser\My\$($BoundParameters.CertificateThumbprint)"
		}
		if (Test-Path -Path "cert:\LocalMachine\My\$($BoundParameters.CertificateThumbprint)") {
			return Get-Item "cert:\LocalMachine\My\$($BoundParameters.CertificateThumbprint)"
		}
		Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Unable to find certificate with thumbprint '$($BoundParameters.CertificateThumbprint)'"
	}
	if ($BoundParameters.CertificateName) {
		if ($certificate = @(Get-ChildItem 'Cert:\CurrentUser\My\').Where{ $_.Subject -eq $BoundParameters.CertificateName -and $_.HasPrivateKey }) {
			return $certificate | Sort-Object NotAfter -Descending | Select-Object -First 1
		}
		if ($certificate = @(Get-ChildItem 'Cert:\LocalMachine\My\').Where{ $_.Subject -eq $BoundParameters.CertificateName -and $_.HasPrivateKey }) {
			return $certificate | Sort-Object NotAfter -Descending | Select-Object -First 1
		}
		Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Unable to find certificate with subject '$($BoundParameters.CertificateName)'"
	}
	if ($BoundParameters.CertificatePath) {
		try { [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($BoundParameters.CertificatePath, $BoundParameters.CertificatePassword) }
		catch {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Unable to load certificate from file '$($BoundParameters.CertificatePath)': $_" -ErrorRecord $_
		}
	}
}

function Resolve-RequestUri {
	<#
	.SYNOPSIS
		Resolves the actual Uri used for a request in Invoke-EntraRequest.
	
	.DESCRIPTION
		Resolves the actual Uri used for a request in Invoke-EntraRequest.
		If the path provided is a full url, it will be returned as is.
		Otherwise, any present parameters will be resolved in the base service url before merging it with the specified path.
	
	.PARAMETER TokenObject
		The object representing the token used for the request.
	
	.PARAMETER ServiceObject
		The service object (if any) used with the request.
		The parameters to be inserted into the query will be read from here.
	
	.PARAMETER BoundParameters
		The parameters provided to Invoke-EntraRequest.
	
	.EXAMPLE
		PS C:\> Resolve-RequestUri -TokenObject $tokenObject -ServiceObject $script:_EntraEndpoints.$($tokenObject.Service) -BoundParameters $PSBoundParameters

		Resolves the uri for the needed request based on token, service and parameters provided
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$TokenObject,

		[Parameter(Mandatory = $true)]
		[AllowNull()]
		$ServiceObject,

		[Parameter(Mandatory = $true)]
		$BoundParameters
	)
	process {
		if ($BoundParameters.Path -match '^https{0,1}://') {
			return $BoundParameters.Path
		}

		$serviceUrlBase = $TokenObject.ServiceUrl.Trim()
		foreach ($key in $ServiceObject.Parameters.Keys) {
			$serviceUrlBase = $serviceUrlBase -replace "%$key%", $BoundParameters.$key
		}

		"$($serviceUrlBase.TrimEnd('/'))/$($Path.TrimStart('/'))"
	}
}

function Resolve-ScopeName {
	<#
	.SYNOPSIS
		Normalizes scope names.
	
	.DESCRIPTION
		Normalizes scope names.
		To help manage correct scopes naming with services that don't map directly to their urls.
	
	.PARAMETER Scopes
		The scopes to normalize.
	
	.PARAMETER Resource
		The Resource the scopes are meant for.
	
	.EXAMPLE
		PS C:\> $scopes | Resolve-ScopeName -Resource $Resource
		
		Resolves all them scopes
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Scopes,

		[Parameter(Mandatory = $true)]
		[string]
		$Resource
	)
	process {
		foreach ($scope in $Scopes) {
			foreach ($scope in $Scopes) {
				if ($scope -like 'https://*/*') { $scope }
				elseif ($scope -like 'api:/') { $scope }
				else { "{0}/{1}" -f $Resource, $scope }
			}
		}
	}
}

function Assert-ServiceName {
	<#
	.SYNOPSIS
		Asserts a service name actually exists.
	
	.DESCRIPTION
		Asserts a service name actually exists.
		Used in validation scripts to ensure proper service names were provided.
	
	.PARAMETER Name
		The name of the service to verify.

	.PARAMETER IncludeTokens
		Also include registered token's services in the assertion.
		By default, the assertion will only verify the existence of registered services.
	
	.EXAMPLE
		PS C:\> Assert-ServiceName -Name $_
		
		Returns $true if the service exists and throws a terminating exception if not so.
	#>
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Name,

		[switch]
		$IncludeTokens
	)
	process {
		if ($script:_EntraEndpoints.Keys -contains $Name) { return $true }
		if ($IncludeTokens -and $script:_EntraTokens.Keys -contains $Name) { return $true }

		$serviceNames = $script:_EntraEndpoints.Keys -join ', '
		Write-Warning "Invalid service name: '$Name'. Legal service names: $serviceNames"
		Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Invalid service name: '$Name'. Legal service names: $serviceNames"
	}
}

function global:Get-ServiceCompletion {
	<#
	.SYNOPSIS
		Returns the values to complete for.service names.
	
	.DESCRIPTION
		Returns the values to complete for.service names.
		Use this command in argument completers.
	
	.PARAMETER ArgumentList
		The arguments an argumentcompleter receives.
		The third item will be the word to complete.
	
	.EXAMPLE
		PS C:\> Get-ServiceCompletion -ArgumentList $args
		
		Returns the values to complete for.service names.
	#>
	[OutputType([System.Management.Automation.CompletionResult])]
	[CmdletBinding()]
	param (
		$ArgumentList
	)
	process {
		$wordToComplete = $ArgumentList[2].Trim("'`"")
		foreach ($service in Get-EntraService) {
			if ($service.Name -notlike "$($wordToComplete)*") { continue }

			$text = if ($service.Name -notmatch '\s') { $service.Name }	else { "'$($service.Name)'" }
			[System.Management.Automation.CompletionResult]::new(
				$text,
				$text,
				'Text',
				$service.ServiceUrl
			)
		}
	}
}
$ExecutionContext.InvokeCommand.GetCommand("Get-ServiceCompletion","Function").Visibility = 'Private'

function Assert-EntraConnection
{
<#
	.SYNOPSIS
		Asserts a connection has been established.
	
	.DESCRIPTION
		Asserts a connection has been established.
		Fails the calling command in a terminating exception if not connected yet.
		
	.PARAMETER Service
		The service to which a connection needs to be established.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command.
		Used to execute the terminating exception in the caller scope if needed.

	.PARAMETER RequiredScopes
		Scopes needed, for better error messages.
	
	.EXAMPLE
		PS C:\> Assert-EntraConnection -Service 'Endpoint' -Cmdlet $PSCmdlet
	
		Silently does nothing if already connected to the specified defender for endpoint service.
		Kills the calling command if not yet connected.
#>
	[CmdletBinding()]
	param (
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[Parameter(Mandatory = $true)]
		[string]
		$Service,
		
		[Parameter(Mandatory = $true)]
		$Cmdlet,
		
		[AllowEmptyCollection()]
		[string[]]
		$RequiredScopes
	)
	
	process
	{
		if ($script:_EntraTokens["$Service"]) { return }
		
		$message = "Not connected yet! Use Connect-EntraService to establish a connection to '$Service' first."
		if ($RequiredScopes) { $message = $message + " Scopes required for this call: $($RequiredScopes -join ', ')"}
		Invoke-TerminatingException -Cmdlet $Cmdlet -Message $message -Category ConnectionError
	}
}

function Connect-EntraService {
	<#
	.SYNOPSIS
		Establish a connection to an Entra Service.
	
	.DESCRIPTION
		Establish a connection to an Entra Service.
		Prerequisite before executing any requests / commands.
	
	.PARAMETER ClientID
		ID of the registered/enterprise application used for authentication.

		Supports providing special labels as "ID":
		+ Azure: Resolves to the actual ID of the first party app used by Connect-AzAccount
		+ Graph: Resolves to the actual ID of the first party app used by Connect-MgGraph
	
	.PARAMETER TenantID
		The ID of the tenant/directory to connect to.
	
	.PARAMETER Scopes
		Any scopes to include in the request.
		Only used for interactive/delegate workflows, ignored for Certificate based authentication or when using Client Secrets.

	.PARAMETER Browser
		Use an interactive logon in your default browser.
		This is the default logon experience.

	.PARAMETER RedirectUri
		The Redirect URI to send with the request.
		May be different from the actual local port you want to listen on (e.g. when redirecting to an alternative name on top of localhost).

	.PARAMETER BrowserMode
		How the browser used for authentication is selected.
		Options:
		+ Auto (default): Automatically use the default browser.
		+ PrintLink: The link to open is printed on console and user selects which browser to paste it into (must be used on the same machine)

	.PARAMETER DeviceCode
		Use the Device Code delegate authentication flow.
		This will prompt the user to complete login via browser.

	.PARAMETER RefreshToken
		Use an already existing RefreshToken to authenticate.
		Can be used to connect to multiple services using a single interactive delegate auth flow.

	.PARAMETER RefreshTokenObject
		Use the full token object of a delegate session with a refresh token, to authenticate to another service with this object.
		Can be used to connect to multiple services using a single interactive delegate auth flow.
	
	.PARAMETER Certificate
		The Certificate object used to authenticate with.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificateThumbprint
		Thumbprint of the certificate to authenticate with.
		The certificate must be stored either in the user or computer certificate store.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificateName
		The name/subject of the certificate to authenticate with.
		The certificate must be stored either in the user or computer certificate store.
		The newest certificate with a private key will be chosen.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificatePath
		Path to a PFX file containing the certificate to authenticate with.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificatePassword
		Password to use to read a PFX certificate file.
		Only used together with -CertificatePath.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER ClientSecret
		The client secret configured in the registered/enterprise application.
		
		Part of the Client Secret Certificate authentication workflow.

	.PARAMETER Credential
		The username / password to authenticate with.

		Part of the Resource Owner Password Credential (ROPC) workflow.

	.PARAMETER VaultName
		Name of the Azure Key Vault from which to retrieve the certificate or client secret used for the authentication.
		Secrets retrieved from the vault are not cached, on token expiration they will be retrieved from the Vault again.
		In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
		or are connected via Connect-AzAccount.

	.PARAMETER SecretName
		Name of the secret to use from the Azure Key Vault specified through the '-VaultName' parameter.
		In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
		or are connected via Connect-AzAccount.
		Supports specifying _multiple_ secret names, in which case the first one that works will be used.

	.PARAMETER Identity
		Log on as the Managed Identity of the current system.
		Only works in environments with managed identities, such as Azure Function Apps or Runbooks.

	.PARAMETER IdentityID
		ID of the User-Managed Identity to connect as.
		https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity

	.PARAMETER IdentityType
		Type of the User-Managed Identity.

	.PARAMETER FallBackAzAccount
		When logon as Managed Identity fails, try logging in as current AzAccount.
		This is intended to allow easier local testing of code intended for an MSI environment, such as an Azure Function App.

	.PARAMETER AsAzAccount
		Reuse the existing Az.Accounts session to authenticate.
		This is convenient as no further interaction is needed, but also limited in what scopes are available.
		This authentication flow requires the 'Az.Accounts' module to be present, loaded and connected.
		Use 'Connect-AzAccount' to connect first.

	.PARAMETER ShowDialog
		Whether to show an interactive dialog when connecting using the existing Az.Accounts session.
		Defaults to: "auto"

		Options:
		- auto: Shows dialog only if needed.
		- always: Will always show the dialog, forcing interaction.
		- never: Will never show the dialog. Authentication will fail if interaction is required.

	.PARAMETER Federated
		Use federated credentials to authenticate.
		This authentication flow is specific to a given environment and can for example enable a Github Action in a specific repository on a specific branch to authenticate, without needing to provide (and manage) a credential.
		Some setup is required.

		By default, this command is going to check all provided configurations ("Federation Providers") registered to EntraAuth and use the first that applies.
		Use "-FederationProvider" to pick a specific one to use.
		Use "-Assertion" to handle the federated identity provider outside of EntraAuth and simply provide the result for logon.

	.PARAMETER FederationProvider
		The name of the Federation Provider to use. Overrides the automatic selection.
		Federation Providers are an EntraAuth concept and used to automatically do what is needed to access and use a Federated Credential, based on its environment.
		See the documentation on Register-EntraFederationProvider for more details.

	.PARAMETER Assertion
		The credentials from the federated identity provider to use in an Federated Credentials authentication flow.

	.PARAMETER Service
		The service to connect to.
		Individual commands using Invoke-EntraRequest specify the service to use and thus identify the token needed.
		Defaults to: Graph

	.PARAMETER ServiceUrl
		The base url for requests to the service connecting to.
		Overrides the default service url configured with the service settings.

	.PARAMETER Resource
		The resource to authenticate to.
		Used to authenticate to a service without requiring a full service configuration.
		Automatically implies PassThru.
		This token is not registered as a service and cannot be implicitly  used by Invoke-EntraRequest.
		Also provide the "-ServiceUrl" parameter, if you later want to use this token explicitly in Invoke-EntraRequest.

	.PARAMETER UseRefreshToken
		Use a refresh token if available.
		Only applicable when connecting using a delegate authentication flow.
		If specified, it will look to reuse an existing refresh token for that same client ID & tenant ID, if present,
		making the authentication process non-interactive.
		By default, it would always do the fully interactive authentication flow via Browser.

	.PARAMETER MakeDefault
		Makes this service the new default service for all subsequent Connect-EntraService & Invoke-EntraRequest calls.

	.PARAMETER PassThru
		Return the token received for the current connection.

	.PARAMETER Environment
		What environment this service should connect to.
		Defaults to: 'Global'

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
		Usually determined by service connected to or the "Environment" parameter, but may be overridden in case of need.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID
	
		Establish a connection to the graph API, prompting the user for login on their default browser.

	.EXAMPLE
		PS C:\> connect-EntraService -AsAzAccount

		Establish a connection to the graph API, using the current Az.Accounts session.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -Certificate $cert
	
		Establish a connection to the graph API using the provided certificate.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -CertificatePath C:\secrets\certs\mde.pfx -CertificatePassword (Read-Host -AsSecureString)
	
		Establish a connection to the graph API using the provided certificate file.
		Prompts you to enter the certificate-file's password first.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -Service Endpoint -ClientID $clientID -TenantID $tenantID -ClientSecret $secret
	
		Establish a connection to Defender for Endpoint using a client secret.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -VaultName myVault -Secretname GraphCert
	
		Establish a connection to the graph API, after retrieving the necessary certificate from the specified Azure Key Vault.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'Browser')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Browser')]
		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppCertificate')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Federated')]
		[ArgumentCompleter({ 'Graph', 'Azure' })]
		[string]
		$ClientID,
		
		[Parameter(ParameterSetName = 'Browser')]
		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppCertificate')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Federated')]
		[string]
		$TenantID = 'organizations',
		
		[Parameter(ParameterSetName = 'Browser')]
		[Parameter(ParameterSetName = 'DeviceCode')]
		[Parameter(ParameterSetName = 'Refresh')]
		[Parameter(ParameterSetName = 'RefreshObject')]
		[string[]]
		$Scopes,

		[Parameter(ParameterSetName = 'Browser')]
		[switch]
		$Browser,

		[Parameter(ParameterSetName = 'Browser')]
		[string]
		$RedirectUri,

		[Parameter(ParameterSetName = 'Browser')]
		[ValidateSet('Auto', 'PrintLink')]
		[string]
		$BrowserMode = 'Auto',

		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[switch]
		$DeviceCode,

		[Parameter(Mandatory = $true, ParameterSetName = 'Refresh')]
		[string]
		$RefreshToken,

		[Parameter(Mandatory = $true, ParameterSetName = 'RefreshObject')]
		[EntraToken]
		$RefreshTokenObject,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificateThumbprint,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificateName,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificatePath,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[System.Security.SecureString]
		$CertificatePassword,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[System.Security.SecureString]
		$ClientSecret,

		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[PSCredential]
		$Credential,

		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[string]
		$VaultName,

		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[string[]]
		$SecretName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Identity')]
		[switch]
		$Identity,

		[Parameter(ParameterSetName = 'Identity')]
		[string]
		$IdentityID,

		[Parameter(ParameterSetName = 'Identity')]
		[ValidateSet('ClientID', 'ResourceID', 'PrincipalID')]
		[string]
		$IdentityType = 'ClientID',

		[Parameter(ParameterSetName = 'Identity')]
		[Parameter(ParameterSetName = 'Federated')]
		[switch]
		$FallBackAzAccount,

		[Parameter(Mandatory = $true, ParameterSetName = 'AzAccount')]
		[switch]
		$AsAzAccount,

		[Parameter(ParameterSetName = 'AzAccount')]
		[ValidateSet('Auto', 'Always', 'Never')]
		[string]
		$ShowDialog = 'Auto',

		[Parameter(ParameterSetName = 'Federated')]
		[switch]
		$Federated,

		[Parameter(ParameterSetName = 'Federated')]
		[ArgumentCompleter({
			param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
			foreach ($provider in Get-EntraFederationProvider) {
				if ($provider.Name -notlike "$wordToComplete*") { continue }
				$text = $provider.Name
				if ($text -match '\s') { $text = "'$($provider.Name -replace "'", "''")'" }

				[System.Management.Automation.CompletionResult]::new($text, $text, 'ParameterValue', $provider.Description)
			}
		})]
		[ValidateScript({
			$providers = (Get-EntraFederationProvider).Name
			if ($_ -in $providers) { return $true }

			$message = "Unknown Federation Provider! '$_' - known providers: $($providers -join ', ')"
			Write-Warning $message
			throw $message
		})]
		[string]
		$FederationProvider,

		[Parameter(ParameterSetName = 'Federated')]
		[string]
		$Assertion,

		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ })]
		[string[]]
		$Service = $script:_DefaultService,

		[string]
		$ServiceUrl,

		[string]
		$Resource,

		[Parameter(ParameterSetName = 'Browser')]
		[Parameter(ParameterSetName = 'DeviceCode')]
		[switch]
		$UseRefreshToken,

		[switch]
		$MakeDefault,

		[switch]
		$PassThru,

		[Environment]
		$Environment,

		[string]
		$AuthenticationUrl
	)
	begin {
		$doRegister = $PSBoundParameters.Keys -notcontains 'Resource'
		$doPassThru = $PassThru -or $Resource

		switch ($ClientID) {
			'Graph' { $ClientID = '14d82eec-204b-4c2f-b7e8-296a70dab67e' }
			'Azure' { $ClientID = '1950a258-227b-4e31-a9cf-717495945fc2' }
		}
	}
	process {
		#region UseRereshToken
		$availableToken = $null
		if ($UseRefreshToken) {
			$availableToken = Get-EntraToken | Where-Object {
				$_.ClientID -eq $ClientID -and
				(
					$_.TenantID -eq $TenantID -or
					$TenantID -eq 'organizations'
				) -and
				$_.RefreshToken
			} | Sort-Object ValidUntil -Descending | Select-Object -First 1
		}
		if ($availableToken) {
			$param = @{ }
			foreach ($parameterName in $PSCmdlet.MyInvocation.MyCommand.ParameterSets.Where{ $_.Name -eq 'RefreshObject' }.Parameters.Name) {
				if ($PSBoundParameters.Keys -contains $parameterName) { $param[$parameterName] = $PSBoundParameters[$parameterName] }
			}
			Connect-EntraService @param -RefreshTokenObject $availableToken
			return
		}
		#endregion UseRereshToken

		foreach ($serviceName in $Service) {
			$serviceObject = $null
			if (-not $Resource) {
				$serviceObject = Get-EntraService -Name $serviceName
			}
			else {
				$serviceName = '<custom>'
			}

			#region AuthenticationUrl
			$authUrl = switch ("$Environment") {
				'China' { 'https://login.chinacloudapi.cn' }
				'USGov' { 'https://login.microsoftonline.us' }
				'USGovDOD' { 'https://login.microsoftonline.us' }
				default { 'https://login.microsoftonline.com' }
			}
			if ($AuthenticationUrl) { $authUrl = $AuthenticationUrl.TrimEnd('/') }

			if (
				$serviceObject.AuthenticationUrl -and
				$PSBoundParameters.Keys -notcontains 'Environment' -and
				$PSBoundParameters.Keys -notcontains 'AuthenticationUrl'
			) {
				$authUrl = $serviceObject.AuthenticationUrl
			}
			#endregion AuthenticationUrl

			$commonParam = @{
				ClientID          = $ClientID
				TenantID          = $TenantID
				Resource          = $serviceObject.Resource
				AuthenticationUrl = $authUrl
			}

			#region Service Url
			$effectiveServiceUrl = $ServiceUrl
			if (-not $ServiceUrl -and $serviceObject) { $effectiveServiceUrl = $serviceObject.ServiceUrl }
			if ($Resource) { $commonParam.Resource = $Resource }

			# If users explicitly provide a service URL, who are we to override that?
			if (-not $ServiceUrl) {
				if ('USGovDOD' -eq $Environment) { $effectiveServiceUrl = $effectiveServiceUrl -replace '^https://graph.microsoft.com', 'https://dod-graph.microsoft.us' -replace '^https://manage.azure.com', 'https://manage.usgovcloudapi.net' }
				elseif ($authUrl -eq 'https://login.microsoftonline.us') { $effectiveServiceUrl = $effectiveServiceUrl -replace '^https://graph.microsoft.com', 'https://graph.microsoft.us' -replace '^https://manage.azure.com', 'https://manage.usgovcloudapi.net' }
				elseif ($authUrl -eq 'https://login.chinacloudapi.cn') { $effectiveServiceUrl = $effectiveServiceUrl -replace '^https://graph.microsoft.com', 'https://microsoftgraph.chinacloudapi.cn' -replace '^https://manage.azure.com', 'https://management.core.chinacloudapi.cn' }
			}
			#endregion Service Url
			
			#region Connection
			:main switch ($PSCmdlet.ParameterSetName) {
				#region Browser
				Browser {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }

					Write-Verbose "[$serviceName] Connecting via Browser ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceBrowser @commonParam -SelectAccount -Scopes $scopesToUse -NoReconnect:$($serviceObject.NoRefresh) -BrowserMode $BrowserMode -RedirectUri $RedirectUri -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}
					
					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $false, $authUrl)
					$token.RedirectUri = $RedirectUri
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via Browser ($($token.Scopes -join ', '))"
				}
				#endregion Browser

				#region DeviceCode
				DeviceCode {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }

					Write-Verbose "[$serviceName] Connecting via DeviceCode ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceDeviceCode @commonParam -Scopes $scopesToUse -NoReconnect:$($serviceObject.NoRefresh) -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $true, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via DeviceCode ($($token.Scopes -join ', '))"
				}
				#endregion DeviceCode

				#region RefreshToken
				Refresh {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }
					if (-not $scopesToUse) { $scopesToUse = '.default' }

					Write-Verbose "[$serviceName] Connecting via RefreshToken ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceRefreshToken @commonParam -RefreshToken $RefreshToken -Scopes $scopesToUse -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $false, $authUrl)
					$token.Type = 'Refresh'
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via RefreshToken ($($token.Scopes -join ', '))"
				}
				#endregion RefreshToken

				#region RefreshObject
				RefreshObject {
					$scopesToUse = $Scopes
					if (-not $Scopes) { $scopesToUse = $serviceObject.DefaultScopes }
					if (-not $scopesToUse) { $scopesToUse = '.default' }

					Write-Verbose "[$serviceName] Connecting via RefreshToken ($($scopesToUse -join ', '))"
					try { $result = Connect-ServiceRefreshToken -ClientID $RefreshTokenObject.ClientID -TenantID $RefreshTokenObject.TenantID -Resource $commonParam.Resource -AuthenticationUrl $RefreshTokenObject.AuthenticationUrl -RefreshToken $RefreshTokenObject.RefreshToken -Scopes $scopesToUse -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $RefreshTokenObject.ClientID, $RefreshTokenObject.TenantID, $effectiveServiceUrl, $false, $RefreshTokenObject.AuthenticationUrl)
					$token.Type = 'Refresh'
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via RefreshToken ($($token.Scopes -join ', '))"
				}
				#endregion RefreshObject

				#region ROPC
				UsernamePassword {
					Write-Verbose "[$serviceName] Connecting via Credential"
					try { $result = Connect-ServicePassword @commonParam -Credential $Credential -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $Credential, $effectiveServiceUrl, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via Credential ($($token.Scopes -join ', '))"
				}
				#endregion ROPC

				#region AppSecret
				AppSecret {
					Write-Verbose "[$serviceName] Connecting via AppSecret"
					try { $result = Connect-ServiceClientSecret @commonParam -ClientSecret $ClientSecret -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $ClientSecret, $effectiveServiceUrl, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via AppSecret ($($token.Scopes -join ', '))"
				}
				#endregion AppSecret

				#region AppCertificate
				AppCertificate {
					Write-Verbose "[$serviceName] Connecting via Certificate"
					try { $certificateObject = Resolve-Certificate -BoundParameters $PSBoundParameters }
					catch {
						Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Cannot resolve certificate" -ErrorRecord $_ -Category InvalidArgument
					}

					try { $result = Connect-ServiceCertificate @commonParam -Certificate $certificateObject -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $certificateObject, $effectiveServiceUrl, $authUrl)
					$token.SetTokenMetadata($result)
					Write-Verbose "[$serviceName] Connected via Certificate ($($token.Scopes -join ', '))"
				}
				#endregion AppCertificate
			
				#region KeyVault
				KeyVault {
					Write-Verbose "[$serviceName] Connecting via KeyVault"
					$failure = $null
					foreach ($secretEntry in $SecretName) {
						try { $secret = Get-VaultSecret -VaultName $VaultName -SecretName $secretEntry }
						catch {
							Write-Warning "[$serviceName] Failed to retrieve secret from KeyVault: $_"
							$PSCmdlet.ThrowTerminatingError($_)
						}
						try {
							$result = switch ($secret.Type) {
								Certificate { Connect-ServiceCertificate @commonParam -Certificate $secret.Certificate -ErrorAction Stop }
								ClientSecret { Connect-ServiceClientSecret @commonParam -ClientSecret $secret.ClientSecret -ErrorAction Stop }
							}
						}
						catch {
							Write-Verbose "[$serviceName] Failed to connect using secret $($secretEntry): $_"
							if (-not $failure) { $failure = $_ }
							continue
						}
						$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $effectiveServiceUrl, $VaultName, $secretEntry, $authUrl)
						$token.SetTokenMetadata($result)

						Write-Verbose "[$serviceName] Connected via KeyVault ($($token.Scopes -join ', '))"
						break main
					}
					# Only reached if all secrets failed
					$PSCmdlet.ThrowTerminatingError($failure)
				}
				#endregion KeyVault

				#region Identity
				Identity {
					Write-Verbose "[$serviceName] Connecting via Managed Identity"

					try { $result = Connect-ServiceIdentity -Resource $commonParam.Resource -IdentityID $IdentityID -IdentityType $IdentityType -ErrorAction Stop }
					catch {
						if (-not $FallBackAzAccount) { $PSCmdlet.ThrowTerminatingError($_) }

						try {
							$newParam = @{}
							$validParam = $PSCmdlet.MyInvocation.MyCommand.ParameterSets.Where{$_.Name -eq 'AzAccount'}.Parameters.Name
							foreach ($pair in $PSBoundParameters.GetEnumerator()) {
								if ($pair.Key -notin $validParam) { continue }
								$newParam[$pair.Key] = $pair.Value
							}
							$newParam.AsAzAccount = $true
							Connect-EntraService @newParam

							break main # Successfully connected
						}
						catch {
							Write-Warning "Fallback to AzAccount failed: $_"
						}

						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $effectiveServiceUrl, $IdentityID, $IdentityType)
					$token.SetTokenMetadata($result)

					Write-Verbose "[$serviceName] Connected via Managed Identity ($($token.Scopes -join ', '))"
				}
				#endregion Identity

				#region Federated
				Federated {
					Write-Verbose "[$serviceName] Connecting via Federated Credential"

					try { $result,$provider = Connect-ServiceFederated @commonParam -Assertion $Assertion -Provider $FederationProvider -ErrorAction Stop }
					catch {
						if (-not $FallBackAzAccount) { $PSCmdlet.ThrowTerminatingError($_) }

						try {
							$newParam = @{}
							$validParam = $PSCmdlet.MyInvocation.MyCommand.ParameterSets.Where{$_.Name -eq 'AzAccount'}.Parameters.Name
							foreach ($pair in $PSBoundParameters.GetEnumerator()) {
								if ($pair.Key -notin $validParam) { continue }
								$newParam[$pair.Key] = $pair.Value
							}
							$newParam.AsAzAccount = $true
							Connect-EntraService @newParam

							break main # Successfully connected
						}
						catch {
							Write-Warning "Fallback to AzAccount failed: $_"
						}

						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $ClientID, $TenantID, $provider, $effectiveServiceUrl, $authUrl)
					$token.SetTokenMetadata($result)

					Write-Verbose "[$serviceName] Connected via Federated Credential ($($token.Scopes -join ', '))"
				}
				#endregion Federated

				#region AzAccount
				AzAccount {
					Write-Verbose "[$serviceName] Connecting via existing Az.Accounts session"

					try { $result = Connect-ServiceAzure -Resource $commonParam.Resource -ShowDialog $ShowDialog -ErrorAction Stop }
					catch {
						Write-Warning "[$serviceName] Failed to connect: $_"
						$PSCmdlet.ThrowTerminatingError($_)
					}

					$token = [EntraToken]::new($serviceName, $effectiveServiceUrl, $ShowDialog)
					$token.TenantID = $result.TenantID
					$token.ClientID = $result.ClientID
					$token.SetTokenMetadata($result)

					Write-Verbose "[$serviceName] Connected via existing Az.Accounts session ($($token.Scopes -join ', '))"
				}
				#endregion AzAccount
			}
			#endregion Connection

			#region Copy Service Metadata
			if ($serviceObject) {
				if ($serviceObject.Query.Count -gt 0) {
					$token.Query = $serviceObject.Query.Clone()
				}
				if ($serviceObject.Header.Count -gt 0) {
					$token.Header = $serviceObject.Header.Clone()
				}
				if ($serviceObject.RawOnly) {
					$token.RawOnly = $true
				}
			}
			if ($doRegister) { $script:_EntraTokens[$serviceName] = $token }
			#endregion Copy Service Metadata

			if ($MakeDefault -and -not $Resource) {
				$script:_DefaultService = $serviceName
			}
			if ($doPassThru) { $token }
		}
	}
}

function Get-EntraService {
	<#
	.SYNOPSIS
		Returns the list of available Entra ID services that can be connected to.
	
	.DESCRIPTION
		Returns the list of available Entra ID services that can be connected to.
		Includes for each the endpoint/service url and the default requested scopes.
	
	.PARAMETER Name
		Name of the service to return.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-EntraService

		List all available services.
	#>
	[CmdletBinding()]
	param (
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[string]
		$Name = '*'
	)
	process {
		$script:_EntraEndpoints.Values | Where-Object Name -like $Name
	}
}

function Get-EntraToken {
	<#
	.SYNOPSIS
		Returns the session token of an Entra ID connection.
	
	.DESCRIPTION
		Returns the session token of an Entra ID connection.
		The main use for those token objects is calling their "GetHeader()" method to get an authentication header
		that automatically refreshes tokens as needed.
	
	.PARAMETER Service
		The service for which to retrieve the token.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-EntraToken
		
		Returns all current session tokens
	#>
	[CmdletBinding()]
	param (
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[string]
		$Service = '*'
	)
	process {
		$script:_EntraTokens.Values | Where-Object Service -like $Service
	}
}

function Import-EntraToken {
	<#
	.SYNOPSIS
		Imports a token into the local token store.
	
	.DESCRIPTION
		Imports a token into the local token store.
		This command is intended for use in a runspace scenario, for passing tokens from the main runspace into background environments.
		The input-token object is cloned into a runspace-local token object and registered to its service.

		After performing the conversion, it will try to renew the token object.
	
	.PARAMETER Token
		The token object to import.
		Should be a token object created by EntraAuth's Connect-EntraService command.
		Usually returned by Get-EntraToken, after finishing the connection.
	
	.PARAMETER PassThru
		Rather than registering the token into the Entra token store in memory, return it as an object.
		Useful for ronspace-localizing a token not associated with any given service.
	
	.PARAMETER NoRenew
		Do not renew the token after importing it.
		By default, newly localized tokens will try to renew themselves, to avoid parallel use of the same access token instance.
	
	.EXAMPLE
		PS C:\> Import-EntraToken -Token $using:tokens

		Imports all tokens stored in $tokens of the calling runspace.
		For use in scenarios such as background runspaces within "ForEach-Object -Parallel"
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[object[]]
		$Token,

		[switch]
		$PassThru,

		[switch]
		$NoRenew
	)
	process {
		foreach ($tokenObject in $Token) {
			$newToken = [EntraToken]::new()
			foreach ($propertyName in $newToken.PSObject.Properties.Name) {
				if ($null -eq $tokenObject.$propertyName) { continue }
				if ($tokenObject.$propertyName -is [hashtable]) {
					$newToken.$propertyName = $tokenObject.$propertyName.Clone()
				}
				else {
					$newToken.$propertyName = $tokenObject.$propertyName
				}
			}

			if (
				-not $newToken.Service -or
				-not $newToken.AccessToken -or
				-not $newToken.ClientID -or
				-not $newToken.TenantID
			) {
				Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Invalid Input Object! An Entra token object must have a Service, AccessToken, ClientID and TenantID. Item received: $tokenObject"
			}

			#region Renew Token
			if (
				-not $NoRenew -and
				(
					$newToken.Type -notin 'DeviceCode', 'Browser' -or
					$newToken.RefreshToken
				)
			) {
				$newToken.RenewToken()
			}
			#endregion Renew Token

			if ($PassThru) { $newToken }
			else { $script:_EntraTokens[$newToken.Service] = $newToken }
		}
	}
}

function New-EntraCustomToken {
	<#
	.SYNOPSIS
		Create a custom token compatible with EntraAuth.
	
	.DESCRIPTION
		Create a custom token compatible with EntraAuth.
		This allows directly integrating APIs that do not operate with default OAuth into the EntraAuth toolset.
	
	.PARAMETER ServiceUrl
		The URL requests are sent against.
	
	.PARAMETER HeaderCode
		The code that calculates the header (including authentication information) to include in the request.
		The scriptblock receives one argument: The token itself.
		Must return a single hashtable.
	
	.PARAMETER Service
		The name of the service to register the token under.
		Does not have to be a formally registered service, can be an arbitrary name.
		Specifying this parameter prevents the token from being returned as output, unless combined with -PassThru.
	
	.PARAMETER PassThru
		Return the token as output.
		By default, when specifying a service name, this command produces no output.
	
	.PARAMETER TenantID
		TenantID to connect to.
		Purely cosmetic, unless accessed from the header code.
	
	.PARAMETER ClientID
		ClientID to connect as.
		Purely cosmetic, unless accessed from the header code.
	
	.PARAMETER Header
		Header information to include in all requests against this API.
		Additional header entries to include in every request.
		Will be added to those returned from the HeaderCode and need not be considered within that code.
	
	.PARAMETER Query
		Additional query parameters to include in all requests against this API.
	
	.PARAMETER Data
		Additional information to store in the token object.
		Used by the HeaderCode scriptblock.
		Use this parameter to include information such as PATs, API keys or similar pieces of information.
	
	.PARAMETER RawOnly
		All requests throug this token should not use the default response processing.
		This will prevent Invoke-EntraRequest from providing most of its usual assistance.
	
	.EXAMPLE
		PS C:\> New-EntraCustomToken -Service AzDevMyProject -ServiceUrl 'https://dev.azure.com/contoso/myproject/_apis/wit' -Data @{ PAT = $pat } -HeaderCode {
			param ($Token)
			$base64AuthInfo = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(':' + $($Token.Data.PAT | ConvertFrom-SecureString -AsPlainText)))
	        return @{
	            Authorization  = "Basic $base64AuthInfo"
	            'Content-Type' = 'application/json'
	        }
		}

		Registers a new token for Azure DevOps, using PAT to authenticate.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$ServiceUrl,

		[Parameter(Mandatory = $true)]
		[scriptblock]
		$HeaderCode,

		[string]
		$Service,

		[switch]
		$PassThru,

		[string]
		$TenantID = '<Not Specified>',

		[string]
		$ClientID = '<Not Specified>',

		[hashtable]
		$Header = @{},

		[hashtable]
		$Query = @{},

		[hashtable]
		$Data = @{},

		[switch]
		$RawOnly
	)
	process {
		$newToken = [EntraToken]::new()
		$newToken.Type = 'Custom'
		$newToken.ServiceUrl = $ServiceUrl
		$newToken.HeaderCode = $HeaderCode
		if ($Service) { $newToken.Service = $Service }
		else { $newToken.Service = '<Custom>' }
		$newToken.TenantID = $TenantID
		$newToken.ClientID = $ClientID
		$newToken.Header = $Header.Clone()
		$newToken.Query = $Query.Clone()
		$newToken.Data = $Data.Clone()
		$newToken.RawOnly = $RawOnly.ToBool()

		if ($Service) {
			$script:_EntraTokens[$Service] = $newToken
		}
		if ($PassThru -or -not $Service) {
			$newToken
		}
	}
}

function Register-EntraService {
	<#
	.SYNOPSIS
		Define a new Entra ID Service to connect to.
	
	.DESCRIPTION
		Define a new Entra ID Service to connect to.
		This allows defining new endpoints to connect to ... or overriding existing endpoints to a different configuration.
	
	.PARAMETER Name
		Name of the Service.
	
	.PARAMETER ServiceUrl
		The base Url requests will use.
	
	.PARAMETER Resource
		The Resource ID. Used when connecting to identify which scopes of an App Registration to use.
	
	.PARAMETER DefaultScopes
		Default scopes to request.
		Used in interactive delegate flows to provide a good default user experience.
		Default scopes should usually include common read scenarios.

	.PARAMETER Header
		Header data to include in each request.
	
	.PARAMETER HelpUrl
		Link for more information about this service.
		Ideally to documentation that helps setting up the connection.

	.PARAMETER NoRefresh
		Delegate authentication flows should not request refresh tokens.
		By default, delegate authentication flows will automatically request offline_access to get a refresh token.
		This refresh token allows requesting new tokens when the current one is expiring without requiring additional
		interactive logon actions.
		However, not all services support this scope.

	.PARAMETER Parameters
		Extra parameters a request will require.
		It expects a hashtable with the key being the parameter name, and the value being a description of that parameter.
		The ServiceUrl must include a placeholder for each parameter to insert into it.

		Example:
		Parameter: @{ VaultName = 'Name of the Key Vault to execute against' }
		ServiceUrl: https://%VAULTNAME%.vault.azure.net

	.PARAMETER Query
		Extra Query Parameters to automatically include on all requests.

	.PARAMETER RawOnly
		Disable default API response handling.
		By default, when executing a request via Invoke-EntraRequest, the response is processed as if it were a default Graph API standard response.
		Many other MS APIs follow the same standard, but not all do so.
		When enabling this setting on a service, all requests against that service will NOT have that processing applied and instead return raw responses.

	.PARAMETER Environment
		What environment this service should connect to.
		Defaults to: 'Global'

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
		Usually determined by the "Environment" parameter, but may be overridden in case of need.
	
	.EXAMPLE
		PS C:\> Register-EntraService -Name Endpoint -ServiceUrl 'https://api.securitycenter.microsoft.com/api' -Resource 'https://api.securitycenter.microsoft.com'

		Registers the defender for endpoint API as a service.

    .EXAMPLE
        PS C:\> Register-EntraService -Name 'PowerBI' -ServiceUrl 'https://api.powerbi.com/v1.0/myorg' -Resource 'https://analysis.windows.net/powerbi/api' -DefaultScopes @('Dataset.Read.All', 'Report.Read.All') -Header @{ 'Accept' = 'application/json' }

        Registers Power BI REST API service with common read scopes and required headers.

    .EXAMPLE
        PS C:\> Register-EntraService -Name 'SharePointOnline' -ServiceUrl 'https://%TENANT%.sharepoint.com/_api' -Resource 'https://%TENANT%.sharepoint.com' -Parameters @{ Tenant = 'SharePoint tenant name (e.g., contoso)' } -DefaultScopes @('Sites.Read.All') -Query @{ '$format' = 'json' }

        Registers SharePoint Online REST API with dynamic tenant URL, requiring a tenant parameter and automatically formatting responses as JSON.

    .EXAMPLE
        PS C:\> Register-EntraService -Name 'CustomCRM' -ServiceUrl 'https://crm.contoso.com/api/v2' -Resource 'api://contoso-crm-app' -NoRefresh -RawOnly -Header @{ 'X-API-Version' = '2.0'; 'Accept' = 'application/json' }

        Registers a custom CRM API that doesn't support refresh tokens and requires raw response handling with custom API versioning headers.

	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[string]
		$ServiceUrl,

		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[AllowEmptyCollection()]
		[string[]]
		$DefaultScopes = @(),

		[hashtable]
		$Header = @{},

		[string]
		$HelpUrl,

		[switch]
		$NoRefresh,

		[hashtable]
		$Parameters = @{},

		[Hashtable]
		$Query = @{},

		[switch]
		$RawOnly,

		[Environment]
		$Environment = 'Global',

		[string]
		$AuthenticationUrl
	)
	process {
		$command = Get-Command Invoke-EntraRequest
		$badParameters = $Parameters.Keys | Where-Object { $_ -in $command.Parameters.Keys }
		if ($badParameters) {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Cannot define parameters that collide with Invoke-EntraRequest: $($badParameters -join ', ')"
		}
		$authUrl = switch ("$Environment") {
			'China' { 'https://login.chinacloudapi.cn' }
			'USGov' { 'https://login.microsoftonline.us' }
			'USGovDOD' { 'https://login.microsoftonline.us' }
			default { 'https://login.microsoftonline.com' }
		}
		if ($AuthenticationUrl) { $authUrl = $AuthenticationUrl.TrimEnd('/') }

		$script:_EntraEndpoints[$Name] = [PSCustomObject]@{
			PSTypeName        = 'EntraAuth.Service'
			Name              = $Name
			ServiceUrl        = $ServiceUrl
			Resource          = $Resource
			DefaultScopes     = $DefaultScopes
			Header            = $Header
			HelpUrl           = $HelpUrl
			NoRefresh         = $NoRefresh.ToBool()
			Parameters        = $Parameters
			Query             = $Query
			RawOnly           = $RawOnly.ToBool()
			AuthenticationUrl = $authUrl
		}
	}
}

function Set-EntraService {
	<#
	.SYNOPSIS
		Modify the settings on an existing Service configuration.
	
	.DESCRIPTION
		Modify the settings on an existing Service configuration.
		Service configurations are defined using Register-EntraService and define how connections and requests to a specific API service / endpoint are performed.
	
	.PARAMETER Name
		The name of the already existing Service configuration.
	
	.PARAMETER ServiceUrl
		The base Url requests will use.
	
	.PARAMETER Resource
		The Resource ID. Used when connecting to identify which scopes of an App Registration to use.
	
	.PARAMETER DefaultScopes
		Default scopes to request.
		Used in interactive delegate flows to provide a good default user experience.
		Default scopes should usually include common read scenarios.

	.PARAMETER Header
		Header data to include in each request.
	
	.PARAMETER HelpUrl
		Link for more information about this service.
		Ideally to documentation that helps setting up the connection.

	.PARAMETER NoRefresh
		Delegate authentication flows should not request refresh tokens.
		By default, delegate authentication flows will automatically request offline_access to get a refresh token.
		This refresh token allows requesting new tokens when the current one is expiring without requiring additional
		interactive logon actions.
		However, not all services support this scope.
	
	.EXAMPLE
		PS C:\> Set-EntraService -Name Endpoint -ServiceUrl 'https://api-us.securitycenter.microsoft.com/api'

		Changes the service url for the "Endpoint" service to 'https://api-us.securitycenter.microsoft.com/api'.
		Note: It is generally recommened to select the service url most suitable for your tenant, geographically:
		https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api/exposed-apis-list?view=o365-worldwide#versioning
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ })]
		[string]
		$Name,

		[string]
		$ServiceUrl,

		[string]
		$Resource,

		[AllowEmptyCollection()]
		[string[]]
		$DefaultScopes,

		[Hashtable]
		$Header,

		[string]
		$HelpUrl,

		[switch]
		$NoRefresh
	)
	process {
		$service = $script:_EntraEndpoints.$Name
		if ($PSBoundParameters.Keys -contains 'ServiceUrl') { $service.ServiceUrl = $ServiceUrl }
		if ($PSBoundParameters.Keys -contains 'Resource') { $service.Resource = $Resource }
		if ($PSBoundParameters.Keys -contains 'DefaultScopes') { $service.DefaultScopes = $DefaultScopes }
		if ($PSBoundParameters.Keys -contains 'Header') { $service.Header = $Header }
		if ($PSBoundParameters.Keys -contains 'HelpUrl') { $service.HelpUrl = $HelpUrl }
		if ($PSBoundParameters.Keys -contains 'NoRefresh') { $service.HelpUrl = $NoRefresh.ToBool() }
	}
}

function Invoke-EntraRequest {
	<#
	.SYNOPSIS
		Executes a web request against an entra-based service
	
	.DESCRIPTION
		Executes a web request against an entra-based service
		Handles all the authentication details once connected using Connect-EntraService.
	
	.PARAMETER Path
		The relative path of the endpoint to query.
		For example, to retrieve Microsoft Graph users, it would be a plain "users".
		To access details on a particular defender for endpoint machine instead it would look thus: "machines/1e5bc9d7e413ddd7902c2932e418702b84d0cc07"
	
	.PARAMETER Body
		Any body content needed for the request.

    .PARAMETER Query
        Any query content to include in the request.
        In opposite to -Body this is attached to the request Url and usually used for filtering.
	
	.PARAMETER Method
		The Rest Method to use.
		Defaults to GET
	
	.PARAMETER RequiredScopes
		Any authentication scopes needed.
		Used for documentary purposes only.

	.PARAMETER Header
		Any additional headers to include on top of authentication and content-type.

	.PARAMETER ContentType
		Specify the content-type of this request.
		Equivalent to specifying it as a header entry, but added as dedicated parameter for user convenience.
	
	.PARAMETER Service
		Which service to execute against.
		Determines the API endpoint called to.
		Defaults to "Graph"

	.PARAMETER SerializationDepth
		How deeply to serialize the request body when converting it to json.
		Defaults to: 99

	.PARAMETER Token
		A Token as created and maintained by this module.
		If specified, it will override the -Service parameter.

	.PARAMETER NoPaging
		Do not automatically page through responses sets.
		By default, Invoke-EntraRequest is going to keep retrieving result pages until all data has been retrieved.

	.PARAMETER Raw
		Do not process the response object and instead return the raw result returned by the API.

	.PARAMETER DeltaSession
		A hashtable including delta sessions.
		Use together with the delta endpoints, e.g. for the Graph API's user delta endpoint:
		https://learn.microsoft.com/en-us/graph/api/user-delta
		Provide an empty hashtable on the first request, the delta token data will be inserted into it.
		Provide the same token for subsequent delta requests.

		This allows retrieving changes over time, without having to reload the entire dataset.

	.PARAMETER MinimalDelta
		When receiving delta data, only return the changed properties (plus a unique identifier), rather than the full object.
		Only used together with DeltaSession
	
	.EXAMPLE
		PS C:\> Invoke-EntraRequest -Path 'alerts' -RequiredScopes 'Alert.Read'
	
		Return a list of defender alerts.

	.EXAMPLE
		PS C:\> Invoke-EntraRequest -Path 'users/delta' -DeltaSession $delta

		Retrieves all users on first request.
		Subsequent calls will only return users that have been changed in the meantime.
#>
	[CmdletBinding(DefaultParameterSetName = 'default')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		$Body,

		[Hashtable]
		$Query = @{ },
		
		[string]
		$Method = 'GET',
		
		[string[]]
		$RequiredScopes,

		[hashtable]
		$Header = @{},

		[string]
		$ContentType,
		
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ -IncludeTokens })]
		[string]
		$Service = $script:_DefaultService,

		[ValidateRange(1, 666)]
		[int]
		$SerializationDepth = 99,

		[EntraToken]
		$Token,

		[switch]
		$NoPaging,

		[switch]
		$Raw,

		[hashtable]
		$DeltaSession,

		[switch]
		$MinimalDelta
	)
	
	DynamicParam {
		if ($Resource) { return }

		$actualService = $Service
		if (-not $actualService) { $actualService = $script:_DefaultService }
		$serviceObject = $script:_EntraEndpoints.$actualService
		if (-not $serviceObject) { return }
		if ($serviceObject.Parameters.Count -lt 1) { return }

		$results = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
		foreach ($pair in $serviceObject.Parameters.GetEnumerator()) {
			$parameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
			$parameterAttribute.ParameterSetName = '__AllParameterSets'
			$parameterAttribute.Mandatory = $true
			$parameterAttribute.HelpMessage = $pair.Value
			$attributesCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
			$attributesCollection.Add($parameterAttribute)
			$RuntimeParam = [System.Management.Automation.RuntimeDefinedParameter]::new($pair.Key, [object], $attributesCollection)

			$results.Add($pair.Key, $RuntimeParam)
		}

		$results
	}

	begin {
		if ($Token) {
			$tokenObject = $Token
		}
		else {
			Assert-EntraConnection -Service $Service -Cmdlet $PSCmdlet -RequiredScopes $RequiredScopes
			$tokenObject = $script:_EntraTokens.$Service
		}
		
		$serviceObject = $script:_EntraEndpoints.$($tokenObject.Service)
		if ($ContentType) { $Header['Content-Type'] = $ContentType }
	}
	process {
		$parameters = @{
			Method = $Method
			Uri    = Resolve-RequestUri -TokenObject $tokenObject -ServiceObject $serviceObject -BoundParameters $PSBoundParameters
		}
		$originalUri = $parameters.Uri
		
		if ($PSBoundParameters.Keys -contains 'Body') {
			if ($Body -is [string]) {
				$parameters.Body = $Body
			}
			else {
				$parameters.Body = $Body | ConvertTo-Json -Compress -Depth $SerializationDepth
			}
		}
		# In PS5.1, some methods cannot contain a body
		$noBodyMethods = 'Default', 'Get', 'Head'
		if ($PSVersionTable.PSVersion.Major -lt 6 -and $Method -in $noBodyMethods) {
			$parameters.Remove('Body')
		}
		
		$queryClone = $Query.Clone()
		if ($DeltaSession -and $DeltaSession[$originalUri].Token) {
			$queryClone['$deltaToken'] = $DeltaSession[$originalUri].Token
		}
		$parameters.Uri += ConvertTo-QueryString -QueryHash $queryClone -DefaultQuery $tokenObject.Query

		do {
			$tempHeader = $tokenObject.GetHeader().Clone() # GetHeader() automatically refreshes expired tokens
			foreach ($pair in $Header.GetEnumerator()) { $tempHeader[$pair.Key] = $pair.Value }
			if ($MinimalDelta) { $tempHeader['Prefer'] = 'return=minimal' }
			$parameters.Headers = $tempHeader
			Write-Verbose "Executing Request: $($Method) -> $($parameters.Uri)"
			try { $result = Invoke-RestMethod @parameters -ErrorAction Stop }
			catch {
				$letItBurn = $true
				$failure = $_

				if ($_.ErrorDetails.Message) {
					try { $details = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop }
					catch { $details = $_.ErrorDetails.Message }
					if ($details.Error.Code -eq 'TooManyRequests') {
						Write-Verbose "Throttling: $($details.error.message)"
						$delay = 1 + ($details.error.message -replace '^.+ (\d+) .+$', '$1' -as [int])
						if ($delay -gt 5) { Write-Warning "Request is being throttled for $delay seconds" }
						Start-Sleep -Seconds $delay
						try {
							$result = Invoke-RestMethod @parameters -ErrorAction Stop
							$letItBurn = $false
						}
						catch {
							$failure = $_
						}
					}
				}

				if ($letItBurn) {
					Write-Warning "Request failed: $($Method) -> $($parameters.Uri)"
					$PSCmdlet.ThrowTerminatingError($failure)
				}
			}
			if (-not $Raw -and -not $tokenObject.RawOnly -and $result.PSObject.Properties.Where{ $_.Name -eq 'value' }) { $result.Value }
			else { $result }
			$parameters.Uri = $result.'@odata.nextLink'

			if ($DeltaSession -and $result.'@odata.deltaLink') {
				$deltaToken = (($result.'@odata.deltaLink' -split '\?')[1] -split '=')[-1]
				if (-not $DeltaSession[$originalUri]) {
					$DeltaSession[$originalUri] = @{}
				}
				$DeltaSession[$originalUri]['Token'] = $deltaToken
			}
		}
		while ($parameters.Uri -and -not $NoPaging)
	}
}

function Get-EntraFederationProvider {
	<#
	.SYNOPSIS
		Lists all registered Federation Providers.
		
	.DESCRIPTION
		Lists all registered Federation Providers.
		Federation Providers are an EntraAuth concept and used to automatically do what is needed to access and use a Federated Credential, based on its environment.
		See the documentation on Register-EntraFederationProvider for more details.
	
	.PARAMETER Name
		The name of the provider to filter by.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-EntraFederationProvider

		Lists all registered Federation Providers.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	param (
		[ArgumentCompleter({
			param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
			foreach ($provider in Get-EntraFederationProvider) {
				if ($provider.Name -notlike "$wordToComplete*") { continue }
				$text = $provider.Name
				if ($text -match '\s') { $text = "'$($provider.Name -replace "'", "''")'" }

				[System.Management.Automation.CompletionResult]::new($text, $text, 'ParameterValue', $provider.Description)
			}
		})]
		[string]
		$Name = '*'
	)
	process {
		($script:_FederationProviders.Values) | Where-Object Name -Like $Name | Sort-Object Priority
	}
}

function Register-EntraFederationProvider {
	<#
	.SYNOPSIS
		Register logic to automatically retrieve the assertion needed in a Federated Credential authentication flow.
	
	.DESCRIPTION
		Register logic to automatically retrieve the assertion needed in a Federated Credential authentication flow.
		Federated credentials allow granting access to a trusted entity without requiring a secret.

		For example, with that it becomes possible, to authorize a github action to authenticate to Entra.
		However, in order for the Github Action to be able to do that, it first needs to authenticate to Github and get a special token.

		This provider defined here serves to implement that step - and to allow you to do the same for your own providers.

		More Resources on Federated Credentials:
		https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp
		https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow?wt.mc_id=SEC-MVP-5004985#third-case-access-token-request-with-a-federated-credential
	
	.PARAMETER Name
		The name of the Federation Provider.
		Pick something that represents the context the user would expect (e.g. "GithubAction", "FunctionApp", ...).
		It usually would be related to the environment from which you connect.
	
	.PARAMETER Description
		A description of the provider.
		Especially useful to explain non-intuitive setup steps that are required to get things started.
	
	.PARAMETER Priority
		How high the priority of the provider is.
		The lower the number, the earlier it is tested for.
		This property is used when auto-detecting which Federation Provider should be used.
		The first match will stop further processing.
	
	.PARAMETER Test
		A piece of code used to test, whether the Federation Provider can be used in the current situation.
		This is used when trying to automatically detect, which provider to use.
	
	.PARAMETER Code
		Code that generates a JWT token used as an Assertion for the Entra authentication, essentially serving as its secret.
	
	.EXAMPLE
		PS C:\> Register-EntraFederationProvider -Name GithubAction -Priority 10 -Description 'For use within a Github Action. Remember to configure your workflow to use the "id-token: write" permission' -Test $test -Code $authCode
		
		Configures the GithubAction Federation Provider.
		Assuming the scriptblocks provided work, this will allow simply running something like this within a Github Action:
		Connect-EntraService -ClientID $clientID -TenantID $tenantID -Federated
		Hint: This provider is preconfigured in EntraAuth, so this should work as it is. Use Get-EntraFederationProvider to inspect the actual implementing code.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[string]
		$Description,

		[int]
		$Priority = 50,

		[Parameter(Mandatory = $true)]
		[scriptblock]
		$Test,

		[Parameter(Mandatory = $true)]
		[scriptblock]
		$Code
	)
	process {
		$script:_FederationProviders[$Name] = [FederationProvider]@{
			Name        = $Name
			Description = $Description
			Priority    = $Priority
			Test        = $Test
			Code        = $Code
			Type        = 'Registered'
		}
	}
}

function Resolve-EntraFederationProvider {
	<#
	.SYNOPSIS
		Resolves which Federation Provider to use to calculate the Federation Credentials to use.
		
	.DESCRIPTION
		Resolves which Federation Provider to use to calculate the Federation Credentials to use.
		This executes the test code for all registered providers (in the order of their priority) until one applies.

		Federation Providers are an EntraAuth concept and used to automatically do what is needed to access and use a Federated Credential, based on its environment.
		See the documentation on Register-EntraFederationProvider for more details.
	
	.PARAMETER Exclude
		The Federation Provider to skip.
	
	.EXAMPLE
		PS C:\> Resolve-EntraFederationProvider

		Resolves which Federation Provider to use to calculate the Federation Credentials to use.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
	[CmdletBinding()]
	param (
		[ArgumentCompleter({
			param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
			foreach ($provider in Get-EntraFederationProvider) {
				if ($provider.Name -notlike "$wordToComplete*") { continue }
				$text = $provider.Name
				if ($text -match '\s') { $text = "'$($provider.Name -replace "'", "''")'" }

				[System.Management.Automation.CompletionResult]::new($text, $text, 'ParameterValue', $provider.Description)
			}
		})]
		[string[]]
		$Exclude
	)
	process {
		foreach ($provider in Get-EntraFederationProvider | Sort-Object Priority) {
			if ($provider.Name -in $Exclude) { continue }

			if (& $provider.Test) { return $provider }
		}
	}
}

function New-EntraFilterBuilder {
	<#
	.SYNOPSIS
		Creates a new OData-Filter construction helper.
	
	.DESCRIPTION
		Creates a new OData-Filter construction helper.
		This helper class was designed to simplify the creation of OData filters for APIs such as the Microsoft Graph API.
		Call the ".Add(...)" method to specify filter conditions.
		
		There are three ways to do so:
		A) .Add(property, operator, value)
		A single property comparison, with a specific operator and value.
		
		B) .Add(customFilter)
		A custom piece of OData filter text.

		C) .Add(filterbuilder)
		The output of another filterbuilder becomes part of the conditions for this one.
		This allows building complex, nested filter statements.

		Finally, call ".Get()" to retrieve the full OData filter string or ".GetHeader()" to retrieve the filter header hashtable.
		
		For more in-depth help with the type, call the '.GetHelp()' method on the object.

		Useful Resources:
		List of valid filter conditions:
		https://learn.microsoft.com/en-us/graph/filter-query-parameter?tabs=http#operators-and-functions-supported-in-filter-expressions
	
	.PARAMETER Logic
		The logic by which individual filter conditions are merged.
		Options:
		- AND (default)
		- OR

	.EXAMPLE
		PS C:\> $filter = New-EntraFilterBuilder
		PS C:\> $filter.Add('displayName', 'eq', 'John Doe')
		PS C:\> $filter.Add('organization', 'in', @('Contoso', 'Fabrikam'))
		PS C:\> $filter.Get()

		Will return: "displayName eq 'John Doe' and organization in ('Contoso', 'Fabrikam')"
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[OutputType([FilterBuilder])]
	[CmdletBinding()]
	param (
		[ValidateSet('AND','OR')]
		[string]
		$Logic = 'AND'
	)

	process {
		[FilterBuilder]::new($Logic)
	}
}

function New-EntraServiceSelector {
	<#
	.SYNOPSIS
		Creates a helper type designed to help make a module implementing EntraAuth more flexible about what EntraAUth service to use.
	
	.DESCRIPTION
		Creates a helper type designed to help make a module implementing EntraAuth more flexible about what EntraAUth service to use.

		While a module can easily define what service to use when calling Invoke-EntraRequest, this has some concerns:
		+ If multiple modules require the same service, they may interfere with each other by trying to use separate applications or having different scope requirements.
		+ If each module defines their own service instance (e.g. "Graph.MyModule"), then a script using multiple modules needs to authenticate multiple times, even if they all could use the same connection/token.

		The Service Selector aims to be a simple solution to this problem.
		It is intended for _Modules_ that implement EntraAuth, not individual scripts.
		
		To fully execute on this, you will need to implement this in three locations:
		- During Module Import: Declare defaults & Selector.
		- At the beginning of your functions: Select chosen services.
		- When executing requests: Use service as chosen.

		#=======================================================================================================
		# During Module Import
		$script:_services = @{ Graph = 'Graph'; MDE = 'Endpoint' }
		$script:_serviceSelector = New-EntraServiceSelector -DefaultServices $script:_services

		# During the Begin stage of each function using EntraAuth
		begin {
			$services = $script:_serviceSelector.GetServiceMap($ServiceMap) # $ServiceMap is a hashtable parameter offered by your function
			Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Graph
		}

		# When executing the actual request, later in the function
		Invoke-EntraService -Service $services.Graph -Path users
		#=======================================================================================================

		With this, somebody could call your command - let's call it "Get-DepartmentUser" - like this:
		Get-DepartmentUser -ServiceMap @{ Graph = 'GraphBeta' }
		And your function would use the beta version of the Graph api, without affecting any other script or module calling your function.

		Example Implementations:
		- During Module Import:
		  https://github.com/FriedrichWeinmann/EntraAuth.Graph.Application/blob/master/EntraAuth.Graph.Application/internal/scripts/variables.ps1
		- Used in Functions:
		  https://github.com/FriedrichWeinmann/EntraAuth.Graph.Application/blob/3c5e9f3de31fd7946e6fe9ebdb938986165ff5ca/EntraAuth.Graph.Application/functions/Get-EAGAppRegistration.ps1#L78
	
	.PARAMETER DefaultServices
		The Default services to use.
		Provide a hashtable of Labels mapping to EntraAuth services.
		Example:
		@{ Graph = 'Graph'; MDE = 'Endpoint' }
		The key is what you use in your code as a label, the Value is the actual service in EntraAuth.
	
	.EXAMPLE
		PS C:\> $script:_serviceSelector = New-EntraServiceSelector -DefaultServices $script:_services
		
		Creates a new ServiceSelector object and stores it in $script:_serviceSelector
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[OutputType([ServiceSelector])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[hashtable]
		$DefaultServices
	)
	process {
		[ServiceSelector]::new($DefaultServices)
	}
}

# Available Tokens
$script:_EntraTokens = @{}

# Endpoint Configuration for Requests
$script:_EntraEndpoints = @{}

# Plugins for automatic processing of Federated Authentication in the correct context
$script:_FederationProviders = @{}

# The default service to connect to
$script:_DefaultService = 'Graph'

# Registers the default service configurations
$endpointCfg = @{
	Name          = 'Endpoint'
	ServiceUrl    = 'https://api.securitycenter.microsoft.com/api'
	Resource      = 'https://api.securitycenter.microsoft.com'
	DefaultScopes = @()
	Header        = @{ 'Content-Type' = 'application/json' }
	HelpUrl       = 'https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/api/apis-intro?view=o365-worldwide'
}
Register-EntraService @endpointCfg

$securityCfg = @{
	Name          = 'Security'
	ServiceUrl    = 'https://api.security.microsoft.com/api'
	Resource      = 'https://security.microsoft.com/mtp/'
	DefaultScopes = @('AdvancedHunting.Read')
	Header        = @{ 'Content-Type' = 'application/json' }
	HelpUrl       = 'https://learn.microsoft.com/en-us/microsoft-365/security/defender/api-create-app-web?view=o365-worldwide'
}
Register-EntraService @securityCfg

$graphCfg = @{
	Name          = 'Graph'
	ServiceUrl    = 'https://graph.microsoft.com/v1.0'
	Resource      = 'https://graph.microsoft.com'
	DefaultScopes = @()
	HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
}
Register-EntraService @graphCfg

$graphBetaCfg = @{
	Name          = 'GraphBeta'
	ServiceUrl    = 'https://graph.microsoft.com/beta'
	Resource      = 'https://graph.microsoft.com'
	DefaultScopes = @()
	HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
}
Register-EntraService @graphBetaCfg

$azureCfg = @{
	Name          = 'Azure'
	ServiceUrl    = 'https://management.azure.com'
	Resource      = 'https://management.core.windows.net/'
	DefaultScopes = @()
	HelpUrl       = 'https://learn.microsoft.com/en-us/rest/api/azure/?view=rest-resources-2022-12-01'
}
Register-EntraService @azureCfg

$azureKeyVaultCfg = @{
	Name          = 'AzureKeyVault'
	ServiceUrl    = 'https://%VAULTNAME%.vault.azure.net'
	Resource      = 'https://vault.azure.net'
	DefaultScopes = @()
	HelpUrl       = 'https://learn.microsoft.com/en-us/rest/api/keyvault/?view=rest-keyvault-secrets-7.4'
	Parameters    = @{
		VaultName = 'Name of the Key Vault to execute against'
	}
	Query         = @{
		'api-version' = '7.4'
	}
}
Register-EntraService @azureKeyVaultCfg

$logAnalyticsCfg = @{
	Name          = 'LogAnalytics'
	ServiceUrl    = 'https://api.loganalytics.azure.com'
	Resource      = 'https://api.loganalytics.io'
	DefaultScopes = @()
	HelpUrl       = 'https://docs.microsoft.com/en-us/azure/azure-monitor/logs/api/overview'
	Header        = @{
		'Content-Type' = 'application/json'
	}
}
Register-EntraService @logAnalyticsCfg

# Default Federation Providers, to enable easy automatic Federation Authentication

#-> Github Actions
$param = @{
	Name        = 'GithubAction'
	Description = 'For within the runtime of a Github Action runner. The workflow must define the permission "id-token: write", in order for the authentication to be valid.'
	Priority    = 10 # Lower = Attempted earlier
	Test        = {
		if ($env:ACTIONS_ID_TOKEN_REQUEST_URL -and $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN) { return $true }

		# If running in an Action but no token, warn about the misconfiguration
		if (-not $env:GITHUB_ACTION -or -not $env:GITHUB_REPOSITORY) { return }

		Write-Warning @'
Github Action Runner detected, but no token available.
This usually happens based on a misconfiguration, with the Workflow not being granted access to the id-token needed.
Permission needed:
  id-token: write
For more information on Github Action permission configuration, see this documentation:
https://docs.github.com/en/actions/how-tos/writing-workflows/choosing-what-your-workflow-does/controlling-permissions-for-github_token
'@
	}
	Code        = {
		$response = Invoke-RestMethod -Uri "$env:ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" -Headers @{
			Authorization = "Bearer $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN"
		} -ErrorAction Stop
		$response.Value
	}
}
Register-EntraFederationProvider @param

$param = @{
	Name = 'EntraMSI'
	Description = 'Authenticate as the Managed Identity in the current context.'
	Priority = 20
	Test = {
		try {
			$null = Connect-EntraService -Identity -Resource 'api://AzureADTokenExchange' -ErrorAction Stop
			$true
		}
		catch { $false }
	}
	code = {
		(Connect-EntraService -Identity -Resource 'api://AzureADTokenExchange').AccessToken
	}
}
Register-EntraFederationProvider @param