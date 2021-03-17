Set-PSFScriptblock -Name 'PSFramework.Validate.Filter.ConditionName' -Scriptblock {
	$_ -match '^[\d\w_]+$' -and $_ -notin 0,1
} -Global