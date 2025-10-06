function Wait-PSFRunspaceWorkflow {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    [CmdletBinding(DefaultParameterSetName = 'Closed')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'QueueTimeout')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Closed')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Count')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Reference')]
        [string]
        $Queue,

        [Parameter(Mandatory = $true, ParameterSetName = 'WorkerClosed')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkerCount')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkerReference')]
        [string]
        $WorkerName,

        [Parameter(ParameterSetName = 'Closed')]
        [Parameter(Mandatory = $true, ParameterSetName = 'WorkerClosed')]
        [switch]
        $Closed,

        [Parameter(Mandatory = $true, ParameterSetName = 'WorkerCount')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Count')]
        [int]
        $Count,

        [Parameter(Mandatory = $true, ParameterSetName = 'WorkerReference')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Reference')]
        [string]
        $ReferenceQueue,

        [Parameter(ParameterSetName = 'WorkerReference')]
        [Parameter(ParameterSetName = 'Reference')]
        [int]
        $ReferenceMultiplier = 1,

        [Parameter(Mandatory = $true, ParameterSetName = 'QueueTimeout')]
        [PSFramework.Parameter.TimeSpanParameter]
        $QueueTimeout,

        [switch]
        $PassThru,

        # NEW
        [switch]
        $ShowProgress,

        [PSFramework.Parameter.TimeSpanParameter]
        $Timeout,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [PsfArgumentCompleter('PSFramework-runspace-workflow-name')]
        [string[]]
        $Name,

        [Parameter(ValueFromPipeline = $true)]
        [PSFramework.Runspace.RSWorkflow[]]
        $InputObject
    )
    process {
        $resolvedWorkflows = Resolve-PsfRunspaceWorkflow -Name $Name -InputObject $InputObject -Cmdlet $PSCmdlet
        $limit = (Get-Date).AddDays(1)
        if ($Timeout) { $limit = (Get-Date).Add($Timeout) }

        # base progress id counter (simple, monotonic)
        $progressId = 1

        foreach ($resolvedWorkflow in $resolvedWorkflows) {
            $start = Get-Date

            if ($ShowProgress) {
                $wfId = $progressId; $progressId += 1
                Write-Progress -Id $wfId -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Elapsed: 0s" -PercentComplete 0

                $workerIds = @{}
                foreach ($w in $resolvedWorkflow.Workers.Keys) {
                    $runnerId = $progressId; $itemsId = $progressId + 1; $progressId += 2
                    $workerIds[$w] = @{ RunnerId = $runnerId; ItemsId = $itemsId }
                    Write-Progress -Id $runnerId -ParentId $wfId -Activity "Runner: $w" -Status "Initializing..." -PercentComplete 0
                    Write-Progress -Id $itemsId  -ParentId $runnerId -Activity "Nb of items" -Status "Initializing..." -PercentComplete -1
                }
            }

            switch ($PSCmdlet.ParameterSetName) {
                'Closed' {
                    while (-not $resolvedWorkflow.Queues.$Queue.Closed) {
                        if ($limit -lt (Get-Date)) {
                            Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
                        }
                        if ($ShowProgress) {
                            $elapsed = ([int]((Get-Date) - $start).TotalSeconds)
                            $overallCurrent = $resolvedWorkflow.Queues.$Queue.TotalItemCount
                            $overallTarget = [math]::Max(1, $overallCurrent + 1)
                            $wfPct = [int][math]::Floor((100.0 * $overallCurrent) / $overallTarget)
                            Write-Progress -Id $wfId -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Mode:Closed | $overallCurrent/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $wfPct

                            foreach ($wk in $resolvedWorkflow.Workers.Keys) {
                                $rid = $workerIds[$wk].RunnerId; $iid = $workerIds[$wk].ItemsId
                                $wObj = $resolvedWorkflow.Workers.$wk

                                $inQName = if ($wObj.PSObject.Properties.Name -contains 'InQueue') { $wObj.InQueue } else { $null }
                                $outQName = $wObj.OutQueue

                                # FIX: resolve queues by name via dynamic property access to avoid null totals
                                $inQ = $null
                                if ($inQName) { $inQ = $resolvedWorkflow.Queues.($inQName) }
                                $outQ = $null
                                if ($outQName) { $outQ = $resolvedWorkflow.Queues.($outQName) }

                                $inTotal = if ($inQ) { $inQ.TotalItemCount }  else { 0 }
                                $outTotal = if ($outQ) { $outQ.TotalItemCount } else { 0 }
                                $outClosed = if ($outQ) { $outQ.Closed }         else { $false }
                                $current = $wObj.CountInputCompleted

                                $runnerPct = [int][math]::Floor((100.0 * $current) / $overallTarget)
                                Write-Progress -Id $rid -ParentId $wfId -Activity "Runner: $wk" -Status "Progress: $current/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $runnerPct

                                # Items status (only print non-empty fields)
                                $parts = @("Completed:$current")
                                if ($inQName) { $parts += "InQ:$inQName total:$inTotal" }
                                if ($outQName) { $parts += "OutQ:$outQName total:$outTotal closed:$outClosed" }
                                $itemStatus = ($parts -join ' | ')
                                Write-Progress -Id $iid -ParentId $rid -Activity "Nb of items" -Status $itemStatus -PercentComplete -1
                            }
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }
                'WorkerClosed' {
                    $queueObject = $resolvedWorkflow.Queues[$resolvedWorkflow.Workers.$WorkerName.OutQueue]
                    while (-not $queueObject.Closed) {
                        if ($limit -lt (Get-Date)) {
                            Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
                        }
                        if ($ShowProgress) {
                            $elapsed = ([int]((Get-Date) - $start).TotalSeconds)
                            $overallCurrent = $queueObject.TotalItemCount
                            $overallTarget = [math]::Max(1, $overallCurrent + 1)
                            $wfPct = [int][math]::Floor((100.0 * $overallCurrent) / $overallTarget)
                            Write-Progress -Id $wfId -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Mode:WorkerClosed | $overallCurrent/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $wfPct

                            foreach ($wk in $resolvedWorkflow.Workers.Keys) {
                                $rid = $workerIds[$wk].RunnerId; $iid = $workerIds[$wk].ItemsId
                                $wObj = $resolvedWorkflow.Workers.$wk

                                $inQName = if ($wObj.PSObject.Properties.Name -contains 'InQueue') { $wObj.InQueue } else { $null }
                                $outQName = $wObj.OutQueue

                                $inQ = $null
                                if ($inQName) { $inQ = $resolvedWorkflow.Queues.($inQName) }
                                $outQ = $null
                                if ($outQName) { $outQ = $resolvedWorkflow.Queues.($outQName) }

                                $inTotal = if ($inQ) { $inQ.TotalItemCount }  else { 0 }
                                $outTotal = if ($outQ) { $outQ.TotalItemCount } else { 0 }
                                $outClosed = if ($outQ) { $outQ.Closed }         else { $false }
                                $current = $wObj.CountInputCompleted

                                $runnerPct = [int][math]::Floor((100.0 * $current) / $overallTarget)
                                Write-Progress -Id $rid -ParentId $wfId -Activity "Runner: $wk" -Status "Progress: $current/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $runnerPct

                                $parts = @("Completed:$current")
                                if ($inQName) { $parts += "InQ:$inQName total:$inTotal" }
                                if ($outQName) { $parts += "OutQ:$outQName total:$outTotal closed:$outClosed" }
                                $itemStatus = ($parts -join ' | ')
                                Write-Progress -Id $iid -ParentId $rid -Activity "Nb of items" -Status $itemStatus -PercentComplete -1
                            }
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }
                'Count' {
                    while ($resolvedWorkflow.Queues.$Queue.TotalItemCount -lt $Count) {
                        if ($limit -lt (Get-Date)) {
                            Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
                        }
                        if ($ShowProgress) {
                            $elapsed = ([int]((Get-Date) - $start).TotalSeconds)
                            $overallCurrent = $resolvedWorkflow.Queues.$Queue.TotalItemCount
                            $overallTarget = $Count
                            $wfPct = [int][math]::Floor((100.0 * $overallCurrent) / [math]::Max(1, $overallTarget))
                            Write-Progress -Id $wfId -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Mode:Count | $overallCurrent/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $wfPct

                            foreach ($wk in $resolvedWorkflow.Workers.Keys) {
                                $rid = $workerIds[$wk].RunnerId; $iid = $workerIds[$wk].ItemsId
                                $wObj = $resolvedWorkflow.Workers.$wk

                                $inQName = if ($wObj.PSObject.Properties.Name -contains 'InQueue') { $wObj.InQueue } else { $null }
                                $outQName = $wObj.OutQueue

                                $inQ = $null
                                if ($inQName) { $inQ = $resolvedWorkflow.Queues.($inQName) }
                                $outQ = $null
                                if ($outQName) { $outQ = $resolvedWorkflow.Queues.($outQName) }

                                $inTotal = if ($inQ) { $inQ.TotalItemCount }  else { 0 }
                                $outTotal = if ($outQ) { $outQ.TotalItemCount } else { 0 }
                                $outClosed = if ($outQ) { $outQ.Closed }         else { $false }
                                $current = $wObj.CountInputCompleted

                                $runnerPct = [int][math]::Floor((100.0 * $current) / [math]::Max(1, $overallTarget))
                                Write-Progress -Id $rid -ParentId $wfId -Activity "Runner: $wk" -Status "Progress: $current/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $runnerPct

                                $parts = @("Completed:$current")
                                if ($inQName) { $parts += "InQ:$inQName total:$inTotal" }
                                if ($outQName) { $parts += "OutQ:$outQName total:$outTotal closed:$outClosed" }
                                $itemStatus = ($parts -join ' | ')
                                Write-Progress -Id $iid -ParentId $rid -Activity "Nb of items" -Status $itemStatus -PercentComplete -1
                            }
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }
                'WorkerCount' {
                    while ($resolvedWorkflow.Workers.$WorkerName.CountInputCompleted -lt $Count) {
                        if ($limit -lt (Get-Date)) {
                            Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
                        }
                        if ($ShowProgress) {
                            $elapsed = ([int]((Get-Date) - $start).TotalSeconds)
                            $overallCurrent = $resolvedWorkflow.Workers.$WorkerName.CountInputCompleted
                            $overallTarget = $Count
                            $wfPct = [int][math]::Floor((100.0 * $overallCurrent) / [math]::Max(1, $overallTarget))
                            Write-Progress -Id $wfId -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Mode:WorkerCount | $overallCurrent/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $wfPct

                            foreach ($wk in $resolvedWorkflow.Workers.Keys) {
                                $rid = $workerIds[$wk].RunnerId; $iid = $workerIds[$wk].ItemsId
                                $wObj = $resolvedWorkflow.Workers.$wk

                                $inQName = if ($wObj.PSObject.Properties.Name -contains 'InQueue') { $wObj.InQueue } else { $null }
                                $outQName = $wObj.OutQueue

                                $inQ = $null
                                if ($inQName) { $inQ = $resolvedWorkflow.Queues.($inQName) }
                                $outQ = $null
                                if ($outQName) { $outQ = $resolvedWorkflow.Queues.($outQName) }

                                $inTotal = if ($inQ) { $inQ.TotalItemCount }  else { 0 }
                                $outTotal = if ($outQ) { $outQ.TotalItemCount } else { 0 }
                                $outClosed = if ($outQ) { $outQ.Closed }         else { $false }
                                $current = $wObj.CountInputCompleted

                                $runnerPct = [int][math]::Floor((100.0 * $current) / [math]::Max(1, $overallTarget))
                                Write-Progress -Id $rid -ParentId $wfId -Activity "Runner: $wk" -Status "Progress: $current/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $runnerPct

                                $parts = @("Completed:$current")
                                if ($inQName) { $parts += "InQ:$inQName total:$inTotal" }
                                if ($outQName) { $parts += "OutQ:$outQName total:$outTotal closed:$outClosed" }
                                $itemStatus = ($parts -join ' | ')
                                Write-Progress -Id $iid -ParentId $rid -Activity "Nb of items" -Status $itemStatus -PercentComplete -1
                            }
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }
                'Reference' {
                    while ($resolvedWorkflow.Queues.$Queue.TotalItemCount -lt ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)) {
                        if ($limit -lt (Get-Date)) {
                            Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
                        }
                        if ($ShowProgress) {
                            $elapsed = ([int]((Get-Date) - $start).TotalSeconds)
                            $overallCurrent = $resolvedWorkflow.Queues.$Queue.TotalItemCount
                            $overallTarget = ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)
                            $wfPct = [int][math]::Floor((100.0 * $overallCurrent) / [math]::Max(1, $overallTarget))
                            Write-Progress -Id $wfId -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Mode:Reference | $overallCurrent/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $wfPct

                            foreach ($wk in $resolvedWorkflow.Workers.Keys) {
                                $rid = $workerIds[$wk].RunnerId; $iid = $workerIds[$wk].ItemsId
                                $wObj = $resolvedWorkflow.Workers.$wk

                                $inQName = if ($wObj.PSObject.Properties.Name -contains 'InQueue') { $wObj.InQueue } else { $null }
                                $outQName = $wObj.OutQueue

                                $inQ = $null
                                if ($inQName) { $inQ = $resolvedWorkflow.Queues.($inQName) }
                                $outQ = $null
                                if ($outQName) { $outQ = $resolvedWorkflow.Queues.($outQName) }

                                $inTotal = if ($inQ) { $inQ.TotalItemCount }  else { 0 }
                                $outTotal = if ($outQ) { $outQ.TotalItemCount } else { 0 }
                                $outClosed = if ($outQ) { $outQ.Closed }         else { $false }
                                $current = $wObj.CountInputCompleted

                                $runnerPct = [int][math]::Floor((100.0 * $current) / [math]::Max(1, $overallTarget))
                                Write-Progress -Id $rid -ParentId $wfId -Activity "Runner: $wk" -Status "Progress: $current/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $runnerPct

                                $parts = @("Completed:$current")
                                if ($inQName) { $parts += "InQ:$inQName total:$inTotal" }
                                if ($outQName) { $parts += "OutQ:$outQName total:$outTotal closed:$outClosed" }
                                $itemStatus = ($parts -join ' | ')
                                Write-Progress -Id $iid -ParentId $rid -Activity "Nb of items" -Status $itemStatus -PercentComplete -1
                            }
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }
                'WorkerReference' {
                    while ($resolvedWorkflow.Workers.$WorkerName.CountInputCompleted -lt ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)) {
                        if ($limit -lt (Get-Date)) {
                            Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
                        }
                        if ($ShowProgress) {
                            $elapsed = ([int]((Get-Date) - $start).TotalSeconds)
                            $overallCurrent = $resolvedWorkflow.Workers.$WorkerName.CountInputCompleted
                            $overallTarget = ($resolvedWorkflow.Queues.$ReferenceQueue.TotalItemCount * $ReferenceMultiplier)
                            $wfPct = [int][math]::Floor((100.0 * $overallCurrent) / [math]::Max(1, $overallTarget))
                            Write-Progress -Id $wfId -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Mode:WorkerReference | $overallCurrent/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $wfPct

                            foreach ($wk in $resolvedWorkflow.Workers.Keys) {
                                $rid = $workerIds[$wk].RunnerId; $iid = $workerIds[$wk].ItemsId
                                $wObj = $resolvedWorkflow.Workers.$wk

                                $inQName = if ($wObj.PSObject.Properties.Name -contains 'InQueue') { $wObj.InQueue } else { $null }
                                $outQName = $wObj.OutQueue

                                $inQ = $null
                                if ($inQName) { $inQ = $resolvedWorkflow.Queues.($inQName) }
                                $outQ = $null
                                if ($outQName) { $outQ = $resolvedWorkflow.Queues.($outQName) }

                                $inTotal = if ($inQ) { $inQ.TotalItemCount }  else { 0 }
                                $outTotal = if ($outQ) { $outQ.TotalItemCount } else { 0 }
                                $outClosed = if ($outQ) { $outQ.Closed }         else { $false }
                                $current = $wObj.CountInputCompleted

                                $runnerPct = [int][math]::Floor((100.0 * $current) / [math]::Max(1, $overallTarget))
                                Write-Progress -Id $rid -ParentId $wfId -Activity "Runner: $wk" -Status "Progress: $current/$overallTarget | Elapsed:${elapsed}s" -PercentComplete $runnerPct

                                $parts = @("Completed:$current")
                                if ($inQName) { $parts += "InQ:$inQName total:$inTotal" }
                                if ($outQName) { $parts += "OutQ:$outQName total:$outTotal closed:$outClosed" }
                                $itemStatus = ($parts -join ' | ')
                                Write-Progress -Id $iid -ParentId $rid -Activity "Nb of items" -Status $itemStatus -PercentComplete -1
                            }
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }
                'QueueTimeout' {
                    while ($resolvedWorkflow.Queues.$Queue.LastUpdate -gt (Get-Date).AddTicks(-1 * $QueueTimeout.Value.Ticks)) {
                        if ($limit -lt (Get-Date)) {
                            Stop-PSFFunction -String 'Wait-PSFRunspaceWorkflow.Error.Timeout' -StringValues $limit, $resolvedWorkflow.Name -Target $resolvedWorkflow -EnableException $true -Cmdlet $PSCmdlet -Category OperationTimeout
                        }
                        if ($ShowProgress) {
                            $elapsed = ([int]((Get-Date) - $start).TotalSeconds)
                            $sinceLast = (Get-Date) - $resolvedWorkflow.Queues.$Queue.LastUpdate
                            $overallCurrent = $sinceLast.TotalSeconds
                            $overallTarget = $QueueTimeout.Value.TotalSeconds
                            $wfPct = [int][math]::Floor((100.0 * $overallCurrent) / [math]::Max(1, $overallTarget))
                            Write-Progress -Id $wfId -Activity "Workflow: $($resolvedWorkflow.Name)" -Status "Mode:QueueTimeout | $([int]$overallCurrent)s/$([int]$overallTarget)s | Elapsed:${elapsed}s" -PercentComplete $wfPct

                            foreach ($wk in $resolvedWorkflow.Workers.Keys) {
                                $rid = $workerIds[$wk].RunnerId; $iid = $workerIds[$wk].ItemsId
                                $wObj = $resolvedWorkflow.Workers.$wk

                                $inQName = if ($wObj.PSObject.Properties.Name -contains 'InQueue') { $wObj.InQueue } else { $null }
                                $outQName = $wObj.OutQueue

                                $inQ = $null
                                if ($inQName) { $inQ = $resolvedWorkflow.Queues.($inQName) }
                                $outQ = $null
                                if ($outQName) { $outQ = $resolvedWorkflow.Queues.($outQName) }

                                $inTotal = if ($inQ) { $inQ.TotalItemCount }  else { 0 }
                                $outTotal = if ($outQ) { $outQ.TotalItemCount } else { 0 }
                                $outClosed = if ($outQ) { $outQ.Closed }         else { $false }
                                $current = $wObj.CountInputCompleted

                                $runnerPct = [int][math]::Floor((100.0 * $current) / [math]::Max(1, $overallTarget))
                                Write-Progress -Id $rid -ParentId $wfId -Activity "Runner: $wk" -Status "Progress: $current/$([int]$overallTarget) | Elapsed:${elapsed}s" -PercentComplete $runnerPct

                                $parts = @("Completed:$current")
                                if ($inQName) { $parts += "InQ:$inQName total:$inTotal" }
                                if ($outQName) { $parts += "OutQ:$outQName total:$outTotal closed:$outClosed" }
                                $itemStatus = ($parts -join ' | ')
                                Write-Progress -Id $iid -ParentId $rid -Activity "Nb of items" -Status $itemStatus -PercentComplete -1
                            }
                        }
                        Start-Sleep -Milliseconds 200
                    }
                }
            }

            if ($ShowProgress) {
                foreach ($wk in $workerIds.Keys) {
                    Write-Progress -Id $workerIds[$wk].ItemsId -Activity "Nb of items" -Completed
                    Write-Progress -Id $workerIds[$wk].RunnerId -Activity "Runner" -Completed
                }
                Write-Progress -Id $wfId -Activity "Workflow" -Completed
            }

            if ($PassThru) { $resolvedWorkflow }
        }
    }
}
