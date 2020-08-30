function Get-PSFTypeSerializationData
{
<#
	.SYNOPSIS
		Creates a type extension XML for serializing an object
	
	.DESCRIPTION
		Creates a type extension XML for serializing an object
		Use this to register a type with a type serializer, so it will retain its integrity across process borders.
	
		This is relevant in order to have an object retain its type when ...
		- sending it over PowerShell Remoting
		- writing it to file via Export-Clixml and reading it later via Import-Clixml
	
		Note:
		In the default serializer, all types registered must:
		- Have all public properties be read & writable (the write needs not do anything, but it must not throw an exception).
		- All non-public properties will be ignored.
		- Come from an Assembly with a static name (like an existing dll file, not compiled at runtime).
	
	.PARAMETER InputObject
		The type to serialize.
		- Accepts a type object
		- The string name of the type
		- An object, whose type will then be determined
	
	.PARAMETER Mode
		Whether all types listed should be generated as a single definition ('Grouped'; default) or as one definition per type.
		Since multiple files have worse performance, it is generally recommended to group them all in a single file.
	
	.PARAMETER Fragment
		By setting this, the type XML is emitted without the outer XML shell, containing only the <Type> node(s).
		Use this if you want to add the output to existing type extension xml.
	
	.PARAMETER Serializer
		The serializer to use for the conversion.
		By default, the PSFramework serializer is used, which should work well enough, but requires the PSFramework to be present.
	
	.PARAMETER Method
		The serialization method to use.
		By default, the PSFramework serialization method is used, which should work well enough, but requires the PSFramework to be present.
	
	.EXAMPLE
		PS C:\> Get-PSFTypeSerializationData -InputObject 'My.Custom.Type'
	
		Generates an XML text that can be used to register via Update-TypeData.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectUsageOfAssignmentOperator", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFTypeSerializationData')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[object[]]
		$InputObject,
		
		[ValidateSet('Grouped','SingleItem')]
		[string]
		$Mode = "Grouped",
		
		[switch]
		$Fragment,
		
		[string]
		$Serializer = "PSFramework.Serialization.SerializationTypeConverter",
		
		[string]
		$Method = "GetSerializationData"
	)
	
	begin
	{
		#region XML builder functions
		function Get-XmlHeader
		{
			<#
				.SYNOPSIS
					Returns the header for a types XML file
			#>
			[OutputType([string])]
			[CmdletBinding()]
			Param (
				
			)
			
			@"
<?xml version="1.0" encoding="utf-8"?>
<Types>

"@
		}
		
		function Get-XmlBody
		{
			<#
				.SYNOPSIS
					Processes a type into proper XML
			#>
			[OutputType([string])]
			[CmdletBinding()]
			Param (
				[string]
				$Type,
				
				[string]
				$Serializer,
				
				[string]
				$Method
			)
			
			@"

  <!-- $Type -->
  <Type>
    <Name>Deserialized.$Type</Name>
    <Members>
      <MemberSet>
        <Name>PSStandardMembers</Name>
        <Members>
          <NoteProperty>
            <Name>
              TargetTypeForDeserialization
            </Name>
            <Value>
              $Type
            </Value>
          </NoteProperty>
        </Members>
      </MemberSet>
    </Members>
  </Type>
  <Type>
    <Name>$Type</Name>
    <Members>
      <CodeProperty IsHidden="true">
        <Name>SerializationData</Name>
        <GetCodeReference>
          <TypeName>$Serializer</TypeName>
          <MethodName>$Method</MethodName>
        </GetCodeReference>
      </CodeProperty>
    </Members>
    <TypeConverter>
      <TypeName>$Serializer</TypeName>
    </TypeConverter>
  </Type>

"@
		}
		
		function Get-XmlFooter
		{
			<#
				.SYNOPSIS
					Returns the footer for a types XML file
			#>
			[OutputType([string])]
			[CmdletBinding()]
			Param (
				
			)
			@"
</Types>
"@
		}
		#endregion XML builder functions
		
		$types = @()
		if ($Mode -eq 'Grouped')
		{
			if (-not $Fragment) { $xml = Get-XmlHeader }
			else { $xml = "" }
		}
	}
	process
	{
		foreach ($item in $InputObject)
		{
			if ($null -eq $item) { continue }
			$type = $null
			if ($res = $item -as [System.Type]) { $type = $res }
			else { $type = $item.GetType() }
			
			if ($type -in $types) { continue }
			
			switch ($Mode)
			{
				'Grouped' { $xml += Get-XmlBody -Method $Method -Serializer $Serializer -Type $type.FullName }
				'SingleItem'
				{
					if (-not $Fragment)
					{
						$xml = Get-XmlHeader
						$xml += Get-XmlBody -Method $Method -Serializer $Serializer -Type $type.FullName
						$xml += Get-XmlFooter
						$xml
					}
					else
					{
						Get-XmlBody -Method $Method -Serializer $Serializer -Type $type.FullName
					}
				}
			}
			
			$types += $type
		}
	}
	end
	{
		if ($Mode -eq 'Grouped')
		{
			if (-not $Fragment) { $xml += Get-XmlFooter }
			$xml
		}
	}
}