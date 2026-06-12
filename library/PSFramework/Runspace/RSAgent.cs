using PSFramework.PSFCore;
using PSFramework.Utility;
using System;
using System.CodeDom.Compiler;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace PSFramework.Runspace
{
    /// <summary>
    /// An individual runspace workflow agent - one runspace owned by a Worker.
    /// </summary>
    public class RSAgent : IDisposable
    {
        /// <summary>
        /// The ID of the current Agent
        /// </summary>
        public int ID { get; private set; }

        /// <summary>
        /// The Worker this Agent belongs to
        /// </summary>
        public RSWorker Parent { get; private set; }

        /// <summary>
        /// When was the agent last active?
        /// </summary>
        public DateTime LastActivity { get; private set; }

        /// <summary>
        /// What we are currently working on.
        /// </summary>
        public RSWorkItem CurrentItem;

        /// <summary>
        /// ID of the runspace operated by this Agent
        /// </summary>
        public Nullable<Guid> RunspaceID { get; private set; }

        private PsfScriptBlock _Begin;
        private PsfScriptBlock _Process;
        private PsfScriptBlock _End;
        internal PowerShell _PSRuntime;
        internal System.Management.Automation.Runspaces.Runspace _Runspace;
        private bool _Run;

        internal Task MainTask;

        /// <summary>
        /// Create a new agent from a worker
        /// </summary>
        /// <param name="Parent">The parent worker the agent is part of.</param>
        /// <param name="ID">The ID of this specific agent.</param>
        public RSAgent(RSWorker Parent, int ID)
        {
            this.Parent = Parent;
            this.ID = ID;
        }

        /// <summary>
        /// Signal that the agent is active
        /// </summary>
        public void SignalActive()
        {
            LastActivity = DateTime.Now;
        }

        /// <summary>
        /// Prepare and Launch the runspace
        /// </summary>
        internal void Initialize()
        {
            _Begin = Parent.Begin;
            _Process = Parent.ScriptBlock;
            _End = Parent.End;

            InitialSessionState localState = Parent.GetSessionState();
            foreach (string key in Parent.PerRSValues.Keys)
            {
                object data = Parent.PerRSValues[key].Dequeue();
                localState.Variables.Add(new SessionStateVariableEntry(key, data, null));
            }
            localState.Variables.Add(new SessionStateVariableEntry("__PSF_Agent", this, "The current instance of the worker.", ScopedItemOptions.Constant));
            _Runspace = RunspaceFactory.CreateRunspace(localState);
            _Runspace.Open();
            RunspaceID = _Runspace.InstanceId;
            RunspaceHost.RSAgents[RunspaceID.Value] = this;
            SetRunspaceName();
        }

        /// <summary>
        /// Execute the begin phase.
        /// </summary>
        internal bool Begin()
        {
            try {
                using (PowerShell execution = PowerShell.Create())
                {
                    execution.Runspace = _Runspace;
                    execution.AddScript(RSWorker.WorkerBeginCode.ToString(), true);
                    execution.AddArgument(_Begin);
                    execution.Invoke();
                }
            }
            catch (RuntimeException e)
            {
                Parent.ErrorCount++;
                Parent.AddError(e.ErrorRecord, null, RunspaceID.Value);
                return false;
            }
            catch (Exception e)
            {
                Parent.ErrorCount++;
                Parent.AddError(new ErrorRecord(e, "RunspaceError", ErrorCategory.NotSpecified, null), null, RunspaceID.Value);
                return false;
            }
            return true;
        }
        /// <summary>
        /// Process a workitem
        /// </summary>
        /// <param name="Item">The workitem to process</param>
        internal void Process(RSWorkItem Item)
        {
            CurrentItem = Item;
            SignalActive();

            int retryCount = Parent.RetryCount;
            if (Item.RetryCount != null)
                retryCount = Item.RetryCount.Value;

            PsfScriptBlock retryCondition = Parent.RetryCondition;
            if (Item.RetryCondition != null)
                retryCondition = Item.RetryCondition;

            int attempts = 0;
            Exception lastError;

            do
            {
                try
                {
                    Invoke(RSWorker.WorkerProcessCode, Item).GetAwaiter().GetResult();
                    Parent.IncrementInputCompleted();
                    return;
                }
                catch (Exception e)
                {
                    attempts++;
                    lastError = e;
                    if (!ShouldRetry(retryCondition, e, attempts, retryCount))
                        break;
                }
            }
            while (attempts <= retryCount);

            ErrorRecord record;
            if (lastError is RuntimeException)
                record = ((RuntimeException)lastError).ErrorRecord;
            else
                record = new ErrorRecord(lastError, "AgentError", ErrorCategory.NotSpecified, Item.Item);

            Parent.IncrementInputCompleted();
            Parent.ErrorCount++;
            if (RunspaceID != null)
                Parent.AddError(record, Item.Item, RunspaceID.Value);
        }
        /// <summary>
        /// Execute the end phase
        /// </summary>
        internal void End()
        {
            try
            {
                using (PowerShell execution = PowerShell.Create())
                {
                    execution.Runspace = _Runspace;
                    execution.AddScript(RSWorker.WorkerBeginCode.ToString(), true);
                    execution.AddArgument(_End);
                    execution.Invoke();
                }
            }
            catch (RuntimeException e)
            {
                Parent.ErrorCount++;
                Parent.AddError(e.ErrorRecord, null, RunspaceID.Value);
            }
            catch (Exception e)
            {
                Parent.ErrorCount++;
                Parent.AddError(new ErrorRecord(e, "RunspaceError", ErrorCategory.NotSpecified, null), null, RunspaceID.Value);
            }
        }

        /// <summary>
        /// The main task that executes the phases
        /// </summary>
        internal void Execute()
        {
            if (_Begin != null)
            {
                bool succeeded = Begin();
                if (!succeeded)
                {
                    Parent.SignalEnd();
                    Dispose();
                    return;
                }
            }

            #region Main Processing
            while (Parent.State == RSState.Running || Parent.State == RSState.Starting)
            {
                if (Parent.IsDone)
                    break;
                if (Parent.MaxItems > 0 && Parent.MaxItems <= Parent.CountInputCompleted)
                    break;
                if (!_Run)
                    break;

                if (Parent.Throttle != null)
                    Parent.Throttle.GetSlot();

                object inputData;
                if (!Parent.GetNext(out inputData))
                {
                    System.Threading.Thread.Sleep(250);
                    continue;
                }

                RSWorkItem item;
                if (inputData is RSWorkItem)
                    item = (RSWorkItem)inputData;
                else
                    item = new RSWorkItem(inputData);

                Process(item);
            }
            #endregion Main Processing

            if (_End != null)
                End();

            Parent.SignalEnd();
            Dispose();
        }

        /// <summary>
        /// Cleanup everything
        /// </summary>
        public void Dispose()
        {
            RSAgent temp;
            if (RunspaceID != null)
            {
                RunspaceHost.RSAgents.TryRemove(RunspaceID.Value, out temp);
                RunspaceID = null;
            }

            if (_Runspace != null)
            {
                _Runspace.Dispose();
                _Runspace = null;
            }
            if (_PSRuntime != null)
            {
                _PSRuntime.Dispose();
                _PSRuntime = null;
            }
        }
        
        /// <summary>
        /// Whether a failed operation should be repeated.
        /// </summary>
        /// <param name="Condition">The scriptblock determining whether a retry should be done.</param>
        /// <param name="Error">What went wrong with the last execution.</param>
        /// <param name="Attempts">How many attempts have already been made.</param>
        /// <param name="MaxRetries">The maximum number of retries we are willing to attempt.</param>
        /// <returns>Whether another attempt should be performed</returns>
        internal bool ShouldRetry(PsfScriptBlock Condition, Exception Error, int Attempts, int MaxRetries)
        {
            // Exhausted max retry attempts
            if (Attempts > MaxRetries)
                return false;

            // No Condition = Always Retry
            if (Condition == null)
                return true;

            ErrorRecord errorObject;
            if (Error is RuntimeException)
                errorObject = (Error as RuntimeException).ErrorRecord;
            else
                errorObject = new ErrorRecord(Error, "InvocationError", ErrorCategory.NotSpecified,CurrentItem.Item);

            try
            {
                using (PowerShell runtime = PowerShell.Create())
                {
                    runtime.Runspace = _Runspace;
                    Collection<PSObject> result = runtime.AddScript(RSWorker.WorkerRetryCode.ToString()).AddArgument(Condition).AddArgument(errorObject).AddArgument(CurrentItem).Invoke();
                    if (result.Count < 1)
                        return false;
                    return LanguagePrimitives.IsTrue(result[0]);
                }
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Executes a runspace workitem
        /// </summary>
        /// <param name="Code">The code to execute</param>
        /// <param name="Item">The workitem to process</param>
        /// <returns>The resulting objects to send to the output queue</returns>
        /// <exception cref="TimeoutException">If execution takes longer than the timeout.</exception>
        public async Task<Collection<PSObject>> Invoke(PsfScriptBlock Code, RSWorkItem Item)
        {
            RSTimeout timeoutMode = Parent.TimeoutType;
            if (CurrentItem.TimeoutType != RSTimeout.Undefined)
                timeoutMode = CurrentItem.TimeoutType;

            // Cleanup a Previous command if cleanup failed
            if (_PSRuntime != null)
                _PSRuntime.Dispose();

            _PSRuntime = PowerShell.Create();
            _PSRuntime.Runspace = _Runspace;
            _PSRuntime.AddScript(Code.ToString());
            _PSRuntime.AddArgument(_Process).AddArgument(Item.Item);

            Task<Collection<PSObject>> execution = Task.Run<Collection<PSObject>>(() => _PSRuntime.Invoke());
            if (timeoutMode == RSTimeout.Undefined || timeoutMode == RSTimeout.None)
                return await execution;

            Task waiter = Task.Run(() => Wait());
            Task first = (Task)Await(execution, waiter).GetAwaiter().GetResult();

            // Case: Did not timeout
            if (first == execution)
            {
                // waiter.Dispose();
                return await execution;
            }

            // Case: Timeout
            waiter.Dispose();
            // execution.Dispose();
            _PSRuntime.Stop();
            throw new TimeoutException($"Workitem timed out! {Parent.Workflow.Name}>{Parent.Name}>{ID}: {CurrentItem.Item}");
        }
        private async Task<object> Await(Task Execution, Task Waiter)
        {
            return await Task.WhenAny(Execution, Waiter);
        }

        /// <summary>
        /// Wait until timeout (if any)
        /// </summary>
        public void Wait()
        {
            RSTimeout timeoutMode = Parent.TimeoutType;
            if (CurrentItem.TimeoutType != RSTimeout.Undefined)
                timeoutMode = CurrentItem.TimeoutType;

            if (timeoutMode == RSTimeout.None)
                return;

            TimeSpan wait = Parent.Timeout;
            if (CurrentItem.Timeout != null)
                wait = CurrentItem.Timeout;

            if (timeoutMode == RSTimeout.Start)
            {
                System.Threading.Thread.Sleep((int)wait.TotalMilliseconds);
                return;
            }

            DateTime limit = LastActivity.Add(wait);
            while (true)
            {
                TimeSpan delta = limit - DateTime.Now;
                System.Threading.Thread.Sleep((int)delta.TotalMilliseconds);
                limit = LastActivity.Add(wait);
                if (limit < DateTime.Now)
                    return;
            }
        }

        /// <summary>
        /// Launch the Runspace Agent
        /// </summary>
        public void Start()
        {
            _Run = true;
            Initialize();
            MainTask = Task.Run(() => Execute());
        }

        /// <summary>
        /// End this agent.
        /// </summary>
        public void Stop()
        {
            _Run = false;
            if (!Parent.KillToStop && MainTask != null)
                MainTask.Wait();
            Dispose();
        }

        #region Utilities
        /// <summary>
        /// Applies the name to the runspace managed by this agent.
        /// </summary>
        private void SetRunspaceName()
        {
            try { SetRunspaceNameInternal(); }
            catch { }
        }
        /// <summary>
        /// This entire function will fail on PS4 or older
        /// </summary>
        private void SetRunspaceNameInternal()
        {
            _PSRuntime.Runspace.Name = $"PSF-{Parent.Workflow.Name}-{Parent.Name}-{ID}";
        }
        #endregion Utilities

        /// <summary>
        /// The text representation of this worker
        /// </summary>
        /// <returns>Some text</returns>
        public override string ToString()
        {
            return $"{Parent.Name}-{ID}";
        }
    }
}
