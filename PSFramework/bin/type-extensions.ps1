#region Configuration Static Remove() Compatibility
Update-TypeData -TypeName "System.Collections.Concurrent.ConcurrentDictionary``2[[$([System.String].AssemblyQualifiedName)],[$([PSFramework.Configuration.Config].AssemblyQualifiedName)]]" -MemberType ScriptMethod -MemberName Remove -Value ([scriptblock]::Create(@'
param (
    $Item
)

$dummyItem = $null
$null = $this.TryRemove($Item, [ref] $dummyItem)
'@)) -Force
#endregion Configuration Static Remove() Compatibility