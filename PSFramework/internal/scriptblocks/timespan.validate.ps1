Set-PSFScriptblock -Name 'PSFramework.Validate.TimeSpan.Positive' -Scriptblock {
	if ($_ -is [PSFTimeSpan]) { $_.Value.Ticks -gt 0 }
	else { $_.Ticks -gt 0 }
} -Global