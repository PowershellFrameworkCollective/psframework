# Modifying Members

One of the classic problems in PowerShell, is that modifying the members of an existing object at scale can be quite expensive.
We _can_ extend objects using type extension XML, modifying all objects of a given name, but that falls short when having to privde specific values and is often more complex than we really want to spend time on.

So we fall back to `Add-Member`:

```powershell
$items = foreach ($item in Get-ChildItem C:\Windows) {
  Add-Member -InputObject $item -MemberType NoteProperty -Name NewName -Value "New_$($item.Name)" -PassThru
}
```

With the current PSFramework version, we can do the same, but faster:

```powershell
$items = foreach ($item in Get-ChildItem C:\Windows) {
  [PSFramework.Object.ObjectHost]::AddNoteProperty($item, 'NewName', "New_$($item.Name)")
}
```

## Trust but Verify

So, let's set up a copmparative performance test, modifying 10000 items each:

```powershell
$codeAddMember = {
  $items = foreach ($item in $items1) {
    Add-Member -InputObject $item -MemberType NoteProperty -Name NewName -Value "New_$($item.Name)" -PassThru
  }
}
$codePsfMember = {
  $items = foreach ($item in $items2) {
    [PSFramework.Object.ObjectHost]::AddNoteProperty($item, 'NewName', "New_$($item.Name)")
    $item
  }
}

Measure-PSMDCommand -Iterations 1 -TestSet @{
  AddMember = $codeAddMember
  PsfMember = $codePsfMember
}
```

Resulting in:

```text
Name      Efficiency       Average
----      ----------       -------
PsfMember 1                00:00:00.1567040
AddMember 2.07816775576884 00:00:00.3256572
```

## More than one property

So ... what happens when we want to add more than one property to an object?

```powershell
$props = @{
  Location = 'US'
  Language = 'English'
  Time = Get-Date
}

$codeAddMember = {
  $items = foreach ($item in $items1) {
    foreach ($pair in $props.GetEnumerator()) {
      Add-Member -InputObject $item -MemberType NoteProperty -Name $pair.Key -Value $pair.Value
    }
    $item
  }
}
$codePsfMember = {
  $items = foreach ($item in $items2) {
    [PSFramework.Object.ObjectHost]::AddNoteProperty($item, $props)
    $item
  }
}

Measure-PSMDCommand -Iterations 1 -TestSet @{
  AddMember = $codeAddMember
  PsfMember = $codePsfMember
}
```

```text
Name      Efficiency      Average
----      ----------      -------
PsfMember 1               00:00:00.1670094
AddMember 5.6515561399538 00:00:00.9438630
```
