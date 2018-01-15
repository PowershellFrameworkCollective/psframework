param (
	$ApiKey,
	$WhatIf
)

if ($WhatIf) { Publish-Module "$(System.DefaultWorkingDirectory)\PSFramework" -NuGetApiKey $ApiKey -Force -WhatIf }
else { Publish-Module "$(System.DefaultWorkingDirectory)\PSFramework" -NuGetApiKey $ApiKey -Force }