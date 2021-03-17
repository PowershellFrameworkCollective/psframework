$paramCon = @{
	Module = 'PSFramework'
	Type = 'Static'
}

$null = New-PSFFilterConditionSet -Module PSFramework -Name Environment -Version '1.0.0' -ScriptBlock {
	#region OS Version
	New-PSFFilterCondition @paramCon -Name OSWindows -ScriptBlock {
		$PSVersionTable.PSVersion.Major -lt 6 -or $global:IsWindows
	}
	New-PSFFilterCondition @paramCon -Name OSLinux -ScriptBlock {
		$PSVersionTable.PSVersion.Major -ge 6 -and $global:IsLinux
	}
	New-PSFFilterCondition @paramCon -Name OSMacOS -ScriptBlock {
		$PSVersionTable.PSVersion.Major -ge 6 -and $global:IsMacOS
	}
	#endregion OS Version
	
	#region PS Version
	New-PSFFilterCondition @paramCon -Name PS3 -ScriptBlock {
		$PSVersionTable.PSVersion.Major -eq 3
	}
	New-PSFFilterCondition @paramCon -Name PS4 -ScriptBlock {
		$PSVersionTable.PSVersion.Major -eq 4
	}
	New-PSFFilterCondition @paramCon -Name PS5 -ScriptBlock {
		$PSVersionTable.PSVersion.Major -eq 5
	}
	New-PSFFilterCondition @paramCon -Name PS6 -ScriptBlock {
		$PSVersionTable.PSVersion.Major -eq 6
	}
	New-PSFFilterCondition @paramCon -Name PS7_0 -ScriptBlock {
		$PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -eq 0
	}
	New-PSFFilterCondition @paramCon -Name PS7_1 -ScriptBlock {
		$PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -eq 1
	}
	New-PSFFilterCondition @paramCon -Name PS7_2 -ScriptBlock {
		$PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -eq 2
	}
	New-PSFFilterCondition @paramCon -Name PS5Plus -ScriptBlock {
		$PSVersionTable.PSVersion.Major -ge 5
	}
	New-PSFFilterCondition @paramCon -Name PS6Plus -ScriptBlock {
		$PSVersionTable.PSVersion.Major -ge 6
	}
	New-PSFFilterCondition @paramCon -Name PS7Plus -ScriptBlock {
		$PSVersionTable.PSVersion.Major -ge 7
	}
	#endregion PS Version
	
	#region Elevation
	New-PSFFilterCondition @paramCon -Name Elevated -ScriptBlock {
		if ($PSVersionTable.PSVersion.Major -ge 6 -and $global:IsLinux) { return $true }
		if ($PSVersionTable.PSVersion.Major -ge 6 -and $global:IsLinux) { return $true }
		
		$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
		$principal = New-Object Security.Principal.WindowsPrincipal $identity
		$principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
	}
	#endregion Elevation
	
	#region Pipelines
	New-PSFFilterCondition @paramCon -Name EnvGithubAction -ScriptBlock {
		(Get-Item env:GITHUB_ACTION -ErrorAction Ignore) -as [bool]
	}
	New-PSFFilterCondition @paramCon -Name EnvAzDevPipeline -ScriptBlock {
		(Get-Item 'env:System.CollectionId' -ErrorAction Ignore) -and (Get-Item 'env:System.DefaultWorkingDirectory' -ErrorAction Ignore)
	}
	#endregion Pipelines
}