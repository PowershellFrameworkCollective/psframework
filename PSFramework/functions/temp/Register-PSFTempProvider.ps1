function Register-PSFTempProvider {
<#
	.SYNOPSIS
		Register a plugin extending the ability to define and manage temporary items.
	
	.DESCRIPTION
		Register a plugin extending the ability to define and manage temporary items.
		The Temporary Item Provider implements the logic that makes a temporary item category possible.
		Want to be able to define temporary user acounts?
		Well, this is where you tell the system how that is supposed to work!
	
		Example implementation:
	
		Register-PSFTempProvider -Name TempFile -CreationScript {
			param ($Data)
			$newPath = Join-Path (Get-PSFPath temp) (Get-Random)
			New-Item -Path $newPath -ItemType File
		} -ExistsScript {
			param ($Data, $CreationData)
			Test-Path $CreationData.FullName
		} -DeleteScript {
			param ($Data, $CreationData)
			Remove-Item $CreationData.FullName
		}
	
	.PARAMETER Name
		Name of the Provider, which is referenced by temp items during their creation.
	
	.PARAMETER ExistsScript
		A scriptblock that validates, whether a given item still exists.
		Receives two arguments: $Data and $CreationData
		The former is what was specified when running New-PSFTempItem, the latter what was returned as its result.
	
	.PARAMETER DeleteScript
		Scriptblock that will delete the temp item it is applied to.
		Receives two arguments: $Data and $CreationData
		The former is what was specified when running New-PSFTempItem, the latter what was returned as its result.
	
	.PARAMETER CreationScript
		A scriptblock that is run during New-PSFTempItem.
		It receives a single argument - $Data, as provided to the command - and is expected to perform any creation tasks that might be needed.
		It should either return nothing, or return a single object, not a list of values.
	
	.EXAMPLE
		PS C:\> Register-PSFTempProvider -Name 'aduser' -ExistsScript $existsScript -DeleteScript $deleteScript -CreationScript $creationScript
	
		Registers a provider to create temporary ad users
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PsfValidateScript('PSFramework.Validate.SafeName', ErrorString = 'PSFramework.Validate.SafeName')]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[scriptblock]
		$ExistsScript,
		
		[Parameter(Mandatory = $true)]
		[scriptblock]
		$DeleteScript,
		
		[scriptblock]
		$CreationScript = { }
	)
	
	process {
		$provider = [PSFramework.Temp.TempItemProvider]::new($Name, $CreationScript, $ExistsScript, $DeleteScript)
		$script:tempItems.Providers[$Name] = $provider
	}
}