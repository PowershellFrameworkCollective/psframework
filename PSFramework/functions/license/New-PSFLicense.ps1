function New-PSFLicense
{
<#
	.SYNOPSIS
		Creates a new license object and registers it
	
	.DESCRIPTION
		This function creates a new license object used by the PSFramework licensing component. The license is automatically registered in the current process' license store.
	
	.PARAMETER Product
		The product that is being licensed
	
	.PARAMETER Manufacturer
		The entity that produced the licensed product
	
	.PARAMETER ProductVersion
		The version of the licensed product
	
	.PARAMETER ProductType
		What kind of product is te license for?
		Options: Module, Script, Library, Application, Other
	
	.PARAMETER Name
		Most licenses used have a name. Feel free to register that name as well.
	
	.PARAMETER Version
		What version is the license?
	
	.PARAMETER Date
		When was the product licensed with the registered license
	
	.PARAMETER Type
		Default: Free
		This shows the usual limitations that apply to this license. By Default, licenses are considered free and may be modified, but require attribution when used in your own product.
	
	.PARAMETER Text
		The full text of your license.
	
	.PARAMETER Description
		A description of the content. Useful when describing how some license is used within your own product.
	
	.PARAMETER Parent
		The license of the product within which the product of this license is used.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.
		
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
		PS C:\> New-PSFLicense -Product 'Awesome Test Product' -Manufacturer 'Awesome Inc.' -ProductVersion '1.0.1.0' -ProductType Application -Name FreeBSD -Version "3.0.0.0" -Date (Get-Date -Year 2016 -Month 11 -Day 28 -Hour 0 -Minute 0 -Second 0) -Text @"
		Copyright (c) 2016, Awesome Inc.
		All rights reserved.

		Redistribution and use in source and binary forms, with or without
		modification, are permitted provided that the following conditions are met:

		1. Redistributions of source code must retain the above copyright notice, this
		   list of conditions and the following disclaimer.
		2. Redistributions in binary form must reproduce the above copyright notice,
		   this list of conditions and the following disclaimer in the documentation
		   and/or other materials provided with the distribution.

		THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
		ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
		WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
		DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
		ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
		(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
		LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
		ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
		(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
		SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

		The views and conclusions contained in the software and documentation are those
		of the authors and should not be interpreted as representing official policies,
		either expressed or implied, of the FreeBSD Project.
		"@
	
		This registers the Awesome Test Product as licensed under the common FreeBSD license.
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/New-PSFLicense')]
	[OutputType([PSFramework.License.License])]
	param
	(
		[Parameter(Mandatory = $true)]
		[String]
		$Product,
		
		[String]
		$Manufacturer = "ACME ltd.",
		
		[Version]
		$ProductVersion = "1.0.0.0",
		
		[Parameter(Mandatory = $true)]
		[PSFramework.License.ProductType]
		$ProductType,
		
		[String]
		$Name = "Unknown",
		
		[Version]
		$Version = "1.0.0.0",
		
		[DateTime]
		$Date = (Get-Date -Year 1989 -Month 10 -Day 3 -Hour 0 -Minute 0 -Second 0),
		
		[PSFramework.License.LicenseType]
		$Type = "Free",
		
		[Parameter(Mandatory = $true)]
		[String]
		$Text,
		
		[string]
		$Description,
		
		[PSFramework.License.License]
		$Parent
	)
	
	# Create and fill object
	$license = New-Object PSFramework.License.License -Property @{
		Product	       = $Product
		Manufacturer   = $Manufacturer
		ProductVersion = $ProductVersion
		ProductType    = $ProductType
		LicenseName    = $Name
		LicenseVersion = $Version
		LicenseDate    = $Date
		LicenseType    = $Type
		LicenseText    = $Text
		Description    = $Description
		Parent		   = $Parent
	}
	if (Test-PSFShouldProcess -Action 'Create License' -Target $license -PSCmdlet $PSCmdlet)
	{
		if (-not ([PSFramework.License.LicenseHost]::Get($license)))
		{
			[PSFramework.License.LicenseHost]::Add($license)
		}
		
		return $license
	}
}
