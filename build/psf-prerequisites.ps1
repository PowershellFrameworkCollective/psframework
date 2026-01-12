Invoke-WebRequest https://raw.githubusercontent.com/PowershellFrameworkCollective/PSFramework.NuGet/refs/heads/master/bootstrap.ps1 -UseBasicParsing | Invoke-Expression
Install-PSFPowerShellGet

Install-PSFModule -Name Pester,PSScriptAnalyzer, PlatyPS, PSModuleDevelopment