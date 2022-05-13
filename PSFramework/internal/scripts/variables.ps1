#region Declare runtime variable for the flow control component
$paramNewVariable = @{
	Name  = "psframework_killqueue"
	Value = (New-Object PSFramework.Utility.LimitedConcurrentQueue[int](25))
	Option = 'ReadOnly'
	Scope = 'Script'
	Description = 'Variable that is used to maintain the list of commands to kill. This is used by Test-PSFFunctionInterrupt. Note: The value tested is the hashcade from the callstack item.'
}

New-Variable @paramNewVariable
#endregion Declare runtime variable for the flow control component

#region Declare PSSession Cache
$paramNewVariable2 = @{
	Name  = "psframework_pssessions"
	Value = (New-Object PSFramework.ComputerManagement.PSSessionContainer)
	Option = 'ReadOnly'
	Scope = 'Script'
	Description = 'Variable containing the list of established powershell remoting sessions. This is used by Invoke-PSFCommand to track connections, disconnect expired sessions and reconnect sessions by name.'
}

New-Variable @paramNewVariable2
#endregion Declare PSSession Cache

#region Register Features
Register-PSFFeature -Name 'PSFramework.InheritEnableException' -NotGlobal -Owner PSFramework -Description 'Causes all PSFramework commands with the -EnableException parameter to check, whether the caller has that variable set (e.g. by having a parameter with the same name) and respect that as well.'
Register-PSFFeature -Name 'PSFramework.Stop-PSFFunction.ShowWarning' -Owner PSFramework -Description 'Causes calls to Stop-PSFFunction to always show warnings. By default, using "-EnableException $true" will only throw the exception but not show the warning.'
Register-PSFFeature -Name 'PSFramework.Sort-PSFObject.IgnoreVersionError' -Owner PSFramework -Description 'Causes Sort-PSFObject to ignore parameters that do not exist in the current PowerShell version.'
[PSFramework.Feature.FeatureHost]::WriteGlobalFlag('PSFramework.Sort-PSFObject.IgnoreVersionError', $true) # $true by default
#endregion Register Features

# The main runspace-local host used for the Filter feature
$script:filterContainer = [PSFramework.Filter.FilterContainer]::Filters

# Container for temp items
$script:tempItems = [PSFramework.Temp.TempItemContainer]::new()