function Test-PSFHashtableEquality {
	<#
	.SYNOPSIS
		Compares hashtables on a per-entry (key and value) basis.
	
	.DESCRIPTION
		Compares hashtables on a per-entry basis.
		It ensures both keys and values are equal as PowerShell considers equality.
	
	.PARAMETER Table1
		The first hashtable to compare.
	
	.PARAMETER Table2
		The second hashtable to compare.
	
	.PARAMETER CaseSensitive
		Whether the value-comparison is case sensitive.

	.PARAMETER Recurse
		Whether nested hashtables should be compared.
		Beware: Recursive nesting can lead to an infinite depth recursion.

	.PARAMETER OneDirectional
		If enabled, all entries in $Table1 must be present in $Table2, but not necessarily all entries in Table2 in Table1
		By default, all entries in both hashtables must match the other hashtable's.
	
	.EXAMPLE
		PS C:\> Test-PSFHashtableEquality -Table1 $param -Table2 $oldParam

		Returns whether $param is equal to $oldParam on a per-entry key & value basis.

	.EXAMPLE
		PS C:\> Test-PSFHashtableEquality -Table1 $param -Table2 $oldParam -Recurse

		Returns whether $param is equal to $oldParam on a per-entry key & value basis.
	#>
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[hashtable]
		$Table1,

		[Parameter(Mandatory = $true)]
		[hashtable]
		$Table2,

		[switch]
		$CaseSensitive,

		[switch]
		$Recurse,

		[switch]
		$OneDirectional
	)
	process {
		[PSFramework.Utility.UtilityHost]::ComparePS($Table1, $Table2, $CaseSensitive.ToBool(), $Recurse.ToBool(), $OneDirectional.ToBool())
	}
}