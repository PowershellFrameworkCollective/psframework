function New-PSFHashtable {
	<#
	.SYNOPSIS
		Creates a new PSFHashtable, which can have a default value set.
	
	.DESCRIPTION
		Creates a new PSFHashtable.
		This is a type that acts the same as a regular hashtable for most purposes.
		Its key differentiator is, that it supports defining a default value, in case a key is provided that has not been set before.

		It also comes with a ".SetDefaultValue($object)" method to later change the default value.

		Important note:
		The pseudo-property notation to access values in hashtables also works for a PSFHashtable, but ONLY for keys already defined!
		The default value requires an INDEX notation.
		Example:

		$hashtable = New-PSFHashtable -DefaultValue 42
		$hashtable.Foo # nothing
		$hashtable['Foo'] # 42
	
	.PARAMETER Hashtable
		An original hashtable to build the PSFHashtable around.
		This will prepopulate the hashtable with the key/value pairs of the input hashtable.
		This effectively clones the input hashtable, the new PSFHashtable is not a reference to the original input.
	
	.PARAMETER DefaultValue
		The default value returned by the hashtable, when resolving a key not specified on the hashtable.
	
	.EXAMPLE
		PS C:\> New-PSFHashtable
		
		Returns a simple PSFHashtable, functionally the same as a regular hashtable.
		It comes with a .SetDefaultValue($object) method to later define a default value.

	.EXAMPLE
		PS C:\> New-PSFHashtable -DefaultValue 42

		Returns an empty PSFHashtable which will by default return 42.

	.EXAMPLE
		PS C:\> New-PSFHashtable -Hashtable $originHash -DefaultValue $false

		Returns a PSFHashtable that is a copy of the hashtable in $originHash, which will by default return $false when resolving undefined keys.
	#>
	[CmdletBinding()]
	param (
		[Hashtable]
		$Hashtable = @{ },

		[object]
		$DefaultValue
	)
	process {
		$result = [PSFramework.Object.PsfHashtable]::new($Hashtable)
		if ($PSBoundParameters.Keys -contains 'DefaultValue') {
			$result.SetDefaultValue($DefaultValue)
		}
		$result
	}
}