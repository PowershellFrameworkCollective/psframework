Set-PSFScriptblock -Name 'PSFramework.Validate.SafeName' -Scriptblock {
	$_ -match '^[\d\w_\-\.]+$'
} -Global