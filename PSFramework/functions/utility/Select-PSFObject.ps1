function Select-PSFObject
{
    <#
        .SYNOPSIS
            Wrapper around Select-Object, extends property parameter.
        
        .DESCRIPTION
            Wrapper around Select-Object, extends property parameter.
            
            This function allows specifying in-line transformation of the properties specified without needing to use complex hashtables.
            Without removing the ability to specify just those hashtables.
            
            See the description of the Property parameter for an exhaustive list of legal notations.
        
        .PARAMETER InputObject
            The object(s) to select from.
        
        .PARAMETER Property
            The properties to select.
            - Supports hashtables, which will be passed through to Select-Object.
            - Supports renaming as it is possible in SQL: "Length AS Size" will select the Length property but rename it to size.
            - Supports casting to a specified type: "Address to IPAddress" or "Length to int". Uses PowerShell type-conversion.
            - Supports parsing numbers to sizes: "Length size GB:2" Converts numeric input (presumed to be bytes) to gigabyte with two decimals.
            Also supports toggling on Unit descriptors by adding another element: "Length size GB:2:1"
            - Supports selecting properties from objects in other variables: "ComputerName from VarName" (Will insert the property 'ComputerName' from variable $VarName)
            - Supports filtering when selecting from outside objects: "ComputerName from VarName where ObjectId = Id" (Will insert the property 'ComputerName' from the object in variable $VarName, whose ObjectId property is equal to the inputs Id property)
            
            Important:
            When using this command from another module (not script-files, those are fine), you do not have access to the variables in the calling module.
            In order to select from other variables using the 'from' call, you need to declare the variable global.
        
        .PARAMETER ExcludeProperty
            Properties to not list.
        
        .PARAMETER ExpandProperty
            Properties to expand.
        
        .PARAMETER Unique
            Do not list multiples of the same value.
        
        .PARAMETER Last
            Select the last n items.
        
        .PARAMETER First
            Select the first n items.
        
        .PARAMETER Skip
            Skip the first (or last if used with -Last) n items.
        
        .PARAMETER SkipLast
            Skip the last n items.
        
        .PARAMETER Wait
            Indicates that the cmdlet turns off optimization.Windows PowerShell runs commands in the order that they appear in the command pipeline and lets them generate all objects. By default, if you include a Select-Object command with the First or Index parameters in a command pipeline, Windows PowerShell stops the command that generates the objects as soon as the selected number of objects is generated.
        
        .PARAMETER Index
            Specifies an array of objects based on their index values. Enter the indexes in a comma-separated list.
        
        .PARAMETER ShowProperty
            Only the specified properties will be shown by default.
            Supersedes ShowExcludeProperty.
        
        .PARAMETER ShowExcludeProperty
            Hides the specified properties from the default display style of the output object.
            Is ignored if used together with ShowProperty.
        
        .PARAMETER TypeName
            Adds a typename to the selected object.
            Will automatically prefix the module.

        .PARAMETER KeepInputObject
            Keeps the original input object, adding new properties the select added without removing any.
            This allows you to use this command to add properties without losing the input object's type.
        
        .EXAMPLE
            PS C:\> Get-ChildItem | Select-PSFObject Name, "Length as Size"
            
            Selects the properties Name and Length, renaming Length to Size in the process.
        
        .EXAMPLE
            PS C:\> Import-Csv .\file.csv | Select-PSFObject Name, "Length as Size to DbaSize"
            
            Selects the properties Name and Length, renaming Length to Size and converting it to [DbaSize] (a userfriendly representation of size numbers contained in the dbatools module)
        
        .EXAMPLE
            PS C:\> $obj = [PSCustomObject]@{ Name = "Foo" }
            PS C:\> Get-ChildItem | Select-PSFObject FullName, Length, "Name from obj"
            
            Selects the properties FullName and Length from the input and the Name property from the object stored in $obj
        
        .EXAMPLE
            PS C:\> $list = @()
            PS C:\> $list += [PSCustomObject]@{ Type = "Foo"; ID = 1 }
            PS C:\> $list += [PSCustomObject]@{ Type = "Bar"; ID = 2 }
            PS C:\> $obj | Select-PSFObject Name, "ID from list WHERE Type = Name"
            
            This allows you to LEFT JOIN contents of another variable.
            Note that it can only do simple property-matching at this point.
            
            It will select Name from the objects stored in $obj, and for each of those the ID Property on any object in $list that has a Type property of equal value as Name on the input.
    #>
        [CmdletBinding(DefaultParameterSetName = 'DefaultParameter', RemotingCapability = 'None')]
        param (
            [Parameter(ValueFromPipeline = $true)]
            [psobject]
            $InputObject,
            
            [Parameter(ParameterSetName = 'DefaultParameter', Position = 0)]
            [Parameter(ParameterSetName = 'SkipLastParameter', Position = 0)]
            [PSFramework.Parameter.SelectParameter[]]
            $Property,
            
            [Parameter(ParameterSetName = 'SkipLastParameter')]
            [Parameter(ParameterSetName = 'DefaultParameter')]
            [string[]]
            $ExcludeProperty,
            
            [Parameter(ParameterSetName = 'DefaultParameter')]
            [Parameter(ParameterSetName = 'SkipLastParameter')]
            [string]
            $ExpandProperty,
            
            [switch]
            $Unique,
            
            [Parameter(ParameterSetName = 'DefaultParameter')]
            [ValidateRange(0, 2147483647)]
            [int]
            $Last,
            
            [Parameter(ParameterSetName = 'DefaultParameter')]
            [ValidateRange(0, 2147483647)]
            [int]
            $First,
            
            [Parameter(ParameterSetName = 'DefaultParameter')]
            [ValidateRange(0, 2147483647)]
            [int]
            $Skip,
            
            [Parameter(ParameterSetName = 'SkipLastParameter')]
            [ValidateRange(0, 2147483647)]
            [int]
            $SkipLast,
            
            [Parameter(ParameterSetName = 'IndexParameter')]
            [Parameter(ParameterSetName = 'DefaultParameter')]
            [switch]
            $Wait,
            
            [Parameter(ParameterSetName = 'IndexParameter')]
            [ValidateRange(0, 2147483647)]
            [int[]]
            $Index,
            
            [string[]]
            $ShowProperty,
            
            [string[]]
            $ShowExcludeProperty,
            
            [string]
            $TypeName,

            [switch]
            $KeepInputObject
        )
        
        begin {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                
                $__clonedParameters = @{ }
                foreach ($key in $PSBoundParameters.Keys) {
                    if ($key -notin 'Property','ShowExcludeProperty','ShowProperty','TypeName','KeepInputObject')
                    {
                        $__clonedParameters[$key] = $PSBoundParameters[$key]
                    }
                }
                if (Test-PSFParameterBinding -ParameterName 'Property') {
                    $__clonedParameters['Property'] = $Property.Value
                }
                
                if (-not ($ShowExcludeProperty -or $ShowProperty -or $TypeName -or $KeepInputObject)) {
                    $__noAdjustment = $true
                }
                else {
                    $__noAdjustment = $false
                    if ($ShowProperty) {
                        $__defaultset = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', $ShowProperty)
                        $__standardmembers = [System.Management.Automation.PSMemberInfo[]]@($__defaultset)
                    }
                    if ($TypeName) {
                        $__callerModule = (Get-PSCallStack)[1].InvocationInfo.MyCommand.ModuleName
                        $__typeName = $TypeName
                        if ($__callerModule) { $__typeName = "$($__callerModule).$($TypeName)" }
                    }
                }
                
                $__wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Select-Object', [System.Management.Automation.CommandTypes]::Cmdlet)
                $__scriptCmd = { & $__wrappedCmd @__clonedParameters }
                $__steppablePipeline = $__scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                # If no adjustment is necessary, run as integrated command (better performance)
                if ($__noAdjustment) { $__steppablePipeline.Begin($PSCmdlet) }
                # If Adjustments are necessary, run as addon, allowing us to capture output
                else { $__steppablePipeline.Begin($true) }
            }
            catch {
                throw
            }
        }
        
        process {
            try {
                if ($__noAdjustment) {
                    $__steppablePipeline.Process($InputObject)
                }
                else {
                    $__item = $__steppablePipeline.Process($InputObject)[0]
                    if ($KeepInputObject)
                    {
                        $__itemTemp = $__item
                        $__item = $InputObject

                        foreach ($objectProperty in $__itemTemp.PSObject.Properties)
                        {
                            if ($__item.PSObject.Properties.Name -notcontains $objectProperty.Name)
                            {
                                Add-Member -InputObject $__item -MemberType NoteProperty -Name $objectProperty.Name -Value $objectProperty.Value
                            }
                        }
                    }
                    if ($ShowProperty) {
                        $__item | Add-Member -Force -MemberType MemberSet -Name PSStandardMembers -Value $__standardmembers -ErrorAction SilentlyContinue
                    }
                    elseif ($ShowExcludeProperty) {
                        $__propertiesToShow = @()
                        foreach ($prop in $__item.PSObject.Properties.Name) {
                            if ($prop -notin $ShowExcludeProperty) {
                                $__propertiesToShow += $prop
                            }
                        }
                        $__defaultset = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', $__propertiesToShow)
                        $__standardmembers = [System.Management.Automation.PSMemberInfo[]]@($__defaultset)
                        $__item | Add-Member -Force -MemberType MemberSet -Name PSStandardMembers -Value $__standardmembers -ErrorAction SilentlyContinue
                    }
                    if ($TypeName) {
                        $__item.PSObject.TypeNames.Insert(0, $__typeName)
                    }
                    $__item
                }
            }
            catch {
                throw
            }
        }
        
        end {
            try {
                $__steppablePipeline.End()
            }
            catch {
                throw
            }
        }
    }