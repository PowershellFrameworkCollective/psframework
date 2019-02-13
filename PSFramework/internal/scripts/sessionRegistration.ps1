# Load Session Registrations for the Session Container feature
# See: New-PSSessionContainer

Register-PSFSessionObjectType -DisplayName CimSession -TypeName Microsoft.Management.Infrastructure.CimSession
Register-PSFSessionObjectType -DisplayName PSSession -TypeName System.Management.Automation.Runspaces.PSSession
Register-PSFSessionObjectType -DisplayName SmoServer -TypeName Microsoft.SqlServer.Management.Smo.Server