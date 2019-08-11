
$mappings = @{
	"deserialized.microsoft.activedirectory.management.addomaincontroller" = @("HostName", "Name")
	"microsoft.activedirectory.management.addomaincontroller"			   = @("HostName", "Name")
	"microsoft.sqlserver.management.smo.server"						       = @("NetName", "DomainInstanceName")
	"deserialized.microsoft.sqlserver.management.smo.server"			   = @("NetName", "DomainInstanceName")
	"microsoft.sqlserver.management.smo.linkedserver"					   = @("Name")
	"deserialized.microsoft.sqlserver.management.smo.linkedserver"		   = @("Name")
	"microsoft.activedirectory.management.adcomputer"					   = @("DNSHostName", "Name")
	"deserialized.microsoft.activedirectory.management.adcomputer"		   = @("DNSHostName", "Name")
	"Microsoft.DnsClient.Commands.DnsRecord_A"							   = @("Name", "IPAddress")
	"Deserialized.Microsoft.DnsClient.Commands.DnsRecord_A"			       = @("Name", "IPAddress")
	"Microsoft.DnsClient.Commands.DnsRecord_AAAA"						   = @("Name", "IPAddress")
	"Deserialized.Microsoft.DnsClient.Commands.DnsRecord_AAAA"			   = @("Name", "IPAddress")
}


foreach ($key in $mappings.Keys)
{
	Register-PSFParameterClassMapping -ParameterClass 'Computer' -TypeName $key -Properties $mappings[$key]
}