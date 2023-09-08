function Register-PSFParameterClassMapping
{
<#
	.SYNOPSIS
		Registers types to a parameter classes input interpretation.
	
	.DESCRIPTION
		The parameter classes shipped in PSFramework can be extended to support input of an unknown object type.
		In order to accomplish that, it is necessary to register the name of that type (and the properties to use) using this command.
	
		On input interpretation, it will check the TypeNames property on the PSObject for evaluation.
		This means you can also specify custom PSObjects by giving them a dedicated name.
	
	.PARAMETER ParameterClass
		The parameter class to extend.
	
	.PARAMETER TypeName
		The name of the type to register.
	
	.PARAMETER Properties
		The properties to check.
		When processing an object of this type, it will try to access the properties in this order, trying to make something fit the intended result.
		The first property that is a fit for the parameter class is chosen, other ones are ignored.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.EXAMPLE
		PS C:\> Register-PSFParameterClassMapping -ParameterClass 'Computer' -TypeName 'microsoft.activedirectory.management.adcomputer' -Properties 'DNSHostName', 'Name'
	
		This extends the computer parameter class by ...
		- having it accept the type 'microsoft.activedirectory.management.adcomputer'
		- having it use the 'DNSHostName' property if available, falling back to 'Name' if necessary
#>
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFParameterClassMapping')]
	param (
		[Parameter(Mandatory = $true)]
		[PSFramework.Parameter.ParameterClasses]
		$ParameterClass,
		
		[Parameter(Mandatory = $true)]
		[string]
		$TypeName,
		
		[Parameter(Mandatory = $true)]
		[string[]]
		$Properties,
		
		[switch]
		$EnableException
	)
	
	begin {
		$classes = @{
			Computer = [PSFramework.Parameter.ComputerParameter]
			DateTime = [PSFramework.Parameter.DateTimeParameter]
			TimeSpan = [PSFramework.Parameter.TimeSpanParameter]
			Encoding = [PSFramework.Parameter.EncodingParameter]
			Path = [PSFramework.Parameter.PathFileSystemParameterBase]
		}
	}
	process
	{
		if ("$ParameterClass" -notin $classes.Keys) {
			Stop-PSFFunction -String 'Register-PSFParameterClassMapping.NotImplemented' -StringValues $ParameterClass -EnableException $EnableException -Tag 'fail', 'argument' -Category NotImplemented
			return
		}

		try {
			$classes["$ParameterClass"]::SetTypePropertyMapping($TypeName, $Properties)
		}
		catch {
			Stop-PSFFunction -String 'Register-PSFParameterClassMapping.Registration.Error' -StringValues $ParameterClass, $Typename -EnableException $EnableException -Tag 'fail', '.NET' -ErrorRecord $_
			return
		}
	}
}