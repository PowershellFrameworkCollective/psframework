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

        public RSWorkItem CurrentItem;

        private PsfScriptBlock _Begin;
        private PsfScriptBlock _Process;
        private PsfScriptBlock _End;
        private PowerShell _PSRuntime;

        /// <summary>
        /// Create a new agent from a worker
        /// </summary>
        /// <param name="Parent">The parent worker the agent is part of</param>
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

            RunspaceHost.RSAgents[System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId] = this;

            InitialSessionState localState = Parent.GetSessionState();
            foreach (string key in Parent.PerRSValues.Keys)
            {
                object data = Parent.PerRSValues[key].Dequeue();
                localState.Variables.Add(new SessionStateVariableEntry(key, data, null));
            }
            localState.Variables.Add(new SessionStateVariableEntry("__PSF_Agent", this, "The current instance of the worker.", ScopedItemOptions.Constant));
            _PSRuntime = PowerShell.Create(localState);
            SetRunspaceName();
        }

        /// <summary>
        /// Execute the begin phase.
        /// </summary>
        internal bool Begin()
        {
            try {
                _PSRuntime.AddScript(RSWorker.WorkerBeginCode.ToString(), true);
                _PSRuntime.AddArgument(_Begin);
                _PSRuntime.Invoke();
            }
            catch (RuntimeException e)
            {
                Parent.ErrorCount++;
                Parent.LastError = e.ErrorRecord;
                return false;
            }
            catch (Exception e)
            {
                Parent.ErrorCount++;
                Parent.LastError = new ErrorRecord(e, "RunspaceError", ErrorCategory.NotSpecified, null);
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


        }
        /// <summary>
        /// Execute the end phase
        /// </summary>
        internal void End()
        {
            try
            {
                _PSRuntime.AddScript(RSWorker.WorkerBeginCode.ToString(), true);
                _PSRuntime.AddArgument(_End);
                _PSRuntime.Invoke();
            }
            catch (RuntimeException e)
            {
                Parent.ErrorCount++;
                Parent.LastError = e.ErrorRecord;
                return;
            }
            catch (Exception e)
            {
                Parent.ErrorCount++;
                Parent.LastError = new ErrorRecord(e, "RunspaceError", ErrorCategory.NotSpecified, null);
                return;
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
            RunspaceHost.RSAgents.TryRemove(System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId, out temp);
            _PSRuntime.Dispose();
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

            _PSRuntime.AddScript(Code.ToString());
            _PSRuntime.AddArgument(_Process).AddArgument(Item.Item);

            Task<Collection<PSObject>> execution = Task.Run<Collection<PSObject>>(() => _PSRuntime.Invoke());
            if (timeoutMode == RSTimeout.Undefined || timeoutMode == RSTimeout.None)
                return await execution;

            Task waiter = Task.Run(() => Wait());
            Task first = Await(execution, waiter);

            // Case: Did not timeout
            if (first == execution)
            {
                waiter.Dispose();
                return await execution;
            }

            // Case: Timeout
            waiter.Dispose();
            execution.Dispose();
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
    }
}
