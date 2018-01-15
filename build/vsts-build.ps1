param (
	$ApiKey,
	$WhatIf
)

if ($WhatIf) { Publish-Module "$(System.DefaultWorkingDirectory)\PSFramework" -NuGetApiKey $ApiKey -Force -WhatIf }
else { Publish-Module "$($env:SYSTEM_DEFAULTWORKINGDIRECTORY)\PSFramework" -NuGetApiKey $ApiKey -Force }