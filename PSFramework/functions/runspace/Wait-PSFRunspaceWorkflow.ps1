function Wait-PSFRunspaceWorkflow {
	<#
	.SYNOPSIS
		Wait for a Runspace Workflow to complete.
	
	.DESCRIPTION
		Wait for a Runspace Workflow to complete.
	
	.PARAMETER Queue
		The name of the queue to measure completion by.
		Usually the last output queue in the chain of steps.

	.PARAMETER WorkerName
		The name of the worker to measure completion by.
		Usually the last step in the chain of steps.
	
	.PARAMETER Closed
		The workflow is considered completed, when the queue or worker selected is closed.
	
	.PARAMETER Count
		The workflow is considered completed, when the queue selected has received the specified number of results.
		This looks at the total amount ever provided, not current number queued.
	
	.PARAMETER ReferenceQueue
		The workflow is considered completed, when the queue selected has received the same number of items as the reference queue.
	
	.PARAMETER ReferenceMultiplier
		When comparing the result queue with a reference queue, multiply the number of items in the reference queue by this value.
		Use when the number of output items, based from the original input, scales by a constant multiplier.
		Defaults to 1.

	.PARAMETER QueueTimeout
		Wait based on how long ago the last item was added to the specified queue.
	
	.PARAMETER PassThru
		Pass through the workflow object waiting for.
		Useful to stop it once waiting has completed.

	.PARAMETER Timeout
		Maximum wait time. Throws an error if exceeded.
		Defaults to 1 day.
	
	.PARAMETER Name
		Name of the workflow to wait for.
	
	.PARAMETER InputObject
		A runspace workflow object to wait for.
        
	.PARAMETER ShowProgress
        To show a progressbas while waiting for runspace completion
	
	.EXAMPLE
		PS C:\> $workflow | Wait-PSFRunspaceWorkflow -Queue Done -Count 1000
		
		Wait until 1000 items have been queued to "Done" in total.

	.EXAMPLE
		PS C:\> $workflow | Wait-PSFRunspaceWorkflow -Queue Done -PassThru | Stop-PSFRunspaceWorkflow

		Wait until the "Done" queue has been closed, then stop the workflow.

	.EXAMPLE
		PS C:\> $workflow | Wait-PSFRunspaceWorkflow -Queue Done -ReferenceQueue Input

		Wait until the "Done" queue has processed as many items as there were written to the "Input" queue.
	
	.LINK
		https://psframework.org/documentation/documents/psframework/runspace-workflows.html
	#>

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
