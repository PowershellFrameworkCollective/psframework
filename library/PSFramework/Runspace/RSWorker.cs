using PSFramework.Utility;
using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Runspace Worker Class, implementing one kind of workload over N agents.
    /// </summary>
    public class RSWorker
    {
        /// <summary>
        /// The base code used to operate workers. Provided during module import
        /// </summary>
        public static PsfScriptBlock WorkerCode
        {
            get { return _WorkerCode; }
            set
            {
                if (_WorkerCode == null)
                    _WorkerCode = value;
            }
        }
        private static PsfScriptBlock _WorkerCode;

        /// <summary>
        /// Name of the Worker. Mostly documentary in nature.
        /// </summary>
        public readonly string Name;

        /// <summary>
        /// Name of the input queue, from which it expects to receive its input
        /// </summary>
        public readonly string InQueue;

        /// <summary>
        /// Name of the output queue, to which results are written
        /// </summary>
        public readonly string OutQueue;

        /// <summary>
        /// The actual script code provided by the user during creation of the worker.
        /// </summary>
        public readonly PsfScriptBlock ScriptBlock;

        /// <summary>
        /// Code that is executed when first the worker is launched.
        /// </summary>
        public PsfScriptBlock Begin;
        private PsfScriptBlock _Begin;

        /// <summary>
        /// Code that is executed when at last the worker is closed.
        /// </summary>
        public PsfScriptBlock End;
        private PsfScriptBlock _End;

        /// <summary>
        /// Maximum count of worker threads / runspaces
        /// </summary>
        public int Count
        {
            get { return _Count; }
            set
            {
                if (State != RSState.Pending)
                    throw new InvalidOperationException("Cannot change worker count after launching the worker!");
                _Count = value;
            }
        }
        private int _Count;

        /// <summary>
        /// State of the worker
        /// </summary>
        public RSState State = RSState.Pending;

        /// <summary>
        /// Time the last input was successfully read from the in queue
        /// </summary>
        public DateTime LastInput;

        /// <summary>
        /// Number of input items received
        /// </summary>
        public int CountInput;

        /// <summary>
        /// Number of input items for which processing has completed (irrespective of success or output count)
        /// </summary>
        public int CountInputCompleted;

        /// <summary>
        /// The last time output was enqueued
        /// </summary>
        public DateTime LastOutput;

        /// <summary>
        /// Number of output items which have been enqueued
        /// </summary>
        public int CountOutput;

        /// <summary>
        /// Number of errors that happened during this workers execution
        /// </summary>
        public int ErrorCount;

        /// <summary>
        /// The last error that happened
        /// </summary>
        public ErrorRecord LastError
        {
            get => _LastError;
            set
            {
                Errors.Enqueue(new RSWorkerError(this, value));
                _LastError = value;
            }
        }
        private ErrorRecord _LastError;

        /// <summary>
        /// The last 64 errors that happened
        /// </summary>
        public LimitedConcurrentQueue<RSWorkerError> Errors = new LimitedConcurrentQueue<RSWorkerError>(64);

        /// <summary>
        /// The total number of items ever queued to the input queue
        /// </summary>
        public int InQueueTotalItemCount => workflow.Queues[InQueue].TotalItemCount;

        /// <summary>
        /// Whether all items that have ever been added to the inqueue have already been processed through this worker
        /// </summary>
        public bool Completed => CountInputCompleted >= InQueueTotalItemCount;

        /// <summary>
        /// Whether the inqueue has been closed and fully processed. If so, processing can stop.
        /// </summary>
        public bool IsDone => workflow.Queues[InQueue].Closed && CountInputCompleted >= InQueueTotalItemCount;

        /// <summary>
        /// If this flag is set, worker runspaces will be hard-killed on stop, rather than waiting for them to gracefully shut down
        /// </summary>
        public bool KillToStop;

        /// <summary>
        /// Throttling to respect. Worker will not execute more frequently than this.
        /// </summary>
        public Throttle Throttle;
        
        /// <summary>
        /// The initial session state to use for the background runspaces
        /// </summary>
        public InitialSessionState SessionState;

        /// <summary>
        /// Variables to inject into the background runspace
        /// </summary>
        public Hashtable Variables = new Hashtable();

        /// <summary>
        /// Modules to pre-load into the background runspace
        /// </summary>
        public List<string> Modules = new List<string>();

        /// <summary>
        /// Functions to pass into the background runspace
        /// </summary>
        public Dictionary<string, ScriptBlock> Functions = new Dictionary<string, ScriptBlock>();

        /// <summary>
        /// Variables that are made available for each worker runspace, each with a separate value.
        /// </summary>
        public ConcurrentDictionary<string, RSQueue> PerRSValues = new ConcurrentDictionary<string, RSQueue>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The maximum number of items this worker will process.
        /// </summary>
        public int MaxItems;

        /// <summary>
        /// Whether the last worker runspace finishing should close the out-queue of this worker
        /// </summary>
        public bool CloseOutQueue;

        /// <summary>
        /// Additional Queues to close when done
        /// </summary>
        public string[] QueuesToClose;

        /// <summary>
        /// The workflow owning the worker
        /// </summary>
        public RSWorkflow Workflow => workflow;

        private RSWorkflow workflow;
        private List<RSPowerShellWrapper> runtimes = new List<RSPowerShellWrapper>();

        /// <summary>
        /// Create a new runspace worker
        /// </summary>
        /// <param name="Name">The name of the worker</param>
        /// <param name="InQueue">Name of the input queue to use</param>
        /// <param name="OutQueue">Name of the output queue to use</param>
        /// <param name="ScriptBlock">The code that actually consumes the input</param>
        /// <param name="Workflow">The workflow object running the entire workflow.</param>
        /// <param name="Count">The number of runspaces this worker will maintain.</param>
        public RSWorker(string Name, string InQueue, string OutQueue, PsfScriptBlock ScriptBlock, RSWorkflow Workflow, int Count = 1)
        {
            this.Name = Name;
            this.InQueue = InQueue;
            this.OutQueue = OutQueue;
            this.ScriptBlock = ScriptBlock;
            workflow = Workflow;
            this.Count = Count;
        }

        /// <summary>
        /// Starts the worker, creating the number of runspaces configured after preparing the execution state.
        /// </summary>
        /// <exception cref="InvalidOperationException">Bad language modes or not having configured a workflow is a bad thing.</exception>
        /// <exception cref="ArgumentException">A Count less than 1 is implausible.</exception>
        public void Start()
        {
            if (WorkerCode.LanguageMode != PSLanguageMode.FullLanguage)
                throw new InvalidOperationException("Refusing to launch worker: The registered worker code is not trusted!");

            if (null == workflow)
                throw new InvalidOperationException("Runspace Workflow cannot be null!");

            if (Count < 1)
                throw new ArgumentException("Count cannot be lower than 1!", "Count");

            if (runtimes.Count > 0)
                throw new InvalidOperationException("There are already runspaces running under this worker!");

            AssertFunctionSafety();

            #region Prepare the Initial Session State
            _Begin = Begin;
            _End = End;

            InitialSessionState localState = SessionState;
            if (null == localState)
                localState = workflow.SessionState;
            if (null == localState)
                localState = InitialSessionState.CreateDefault();

            if (workflow.Modules.Count > 0)
                localState.ImportPSModule(workflow.Modules.ToArray());
            if (Modules.Count > 0)
                localState.ImportPSModule(Modules.ToArray());
            localState.ImportPSModulesFromPath(PSFCore.PSFCoreHost.ModuleRoot);

            if (workflow.Functions.Count > 0)
                foreach (string name in workflow.Functions.Keys)
                    localState.Commands.Add(new SessionStateFunctionEntry(name, workflow.Functions[name].ToString()));
            if (Functions.Count > 0)
                foreach (string name in Functions.Keys)
                    localState.Commands.Add(new SessionStateFunctionEntry(name, Functions[name].ToString()));

            if (workflow.Variables.Count > 0)
                foreach (string name in workflow.Variables.Keys)
                    localState.Variables.Add(new SessionStateVariableEntry(name, workflow.Variables[name], null));
            if (Variables.Count > 0)
                foreach (string name in Variables.Keys)
                    localState.Variables.Add(new SessionStateVariableEntry(name, Variables[name], null));
            localState.Variables.Add(new SessionStateVariableEntry("__PSF_Workflow", workflow, "PSF Runspace Workflow, used to manage the data transfer between workers and the state handling of the workload.", ScopedItemOptions.Constant));
            localState.Variables.Add(new SessionStateVariableEntry("__PSF_Worker", this, "PSF Worker. Represents itself in the active runspaces.", ScopedItemOptions.Constant));
            #endregion Prepare the Initial Session State

            State = RSState.Starting;

            #region Launch Runspaces
            for (int i = 0; i < Count; i++)
            {
                PowerShell powershell = PowerShell.Create(localState);
                powershell.AddScript(WorkerCode.ToString()).AddArgument(i);
                runtimes.Add(new RSPowerShellWrapper(powershell, powershell.BeginInvoke()));
            }
            #endregion Launch Runspaces

            State = RSState.Running;
        }

        /// <summary>
        /// Signal all workers to stop and gracefully end them.
        /// </summary>
        public void Stop()
        {
            State = RSState.Stopping;
            foreach (RSPowerShellWrapper runtime in runtimes)
            {
                if (!KillToStop)
                    runtime.Pipe.EndInvoke(runtime.Status);
                runtime.Pipe.Dispose();
            }
            State = RSState.Stopped;

            runtimes = new List<RSPowerShellWrapper>();
        }

        /// <summary>
        /// Increase the count of input items completed
        /// </summary>
        public void IncrementInputCompleted()
        {
            Interlocked.Increment(ref CountInputCompleted);
        }
        /// <summary>
        /// Increase the count of output items produced
        /// </summary>
        public void IncrementOutput()
        {
            Interlocked.Increment(ref CountOutput);
            LastOutput = DateTime.Now;
        }

        /// <summary>
        /// Retrieve the begin scriptblock, localized to the current runspace and set to the global scope, without breaking code trust.
        /// </summary>
        /// <returns>Either null or the globalized scriptblock.</returns>
        public ScriptBlock GetBegin()
        {
            if (null == _Begin)
                return null;
            return _Begin.ToGlobal();
        }
        /// <summary>
        /// Retrieve the end scriptblock, localized to the current runspace and set to the global scope, without breaking code trust.
        /// </summary>
        /// <returns>Either null or the globalized scriptblock.</returns>
        public ScriptBlock GetEnd()
        {
            if (null == _End)
                return null;
            return _End.ToGlobal();
        }

        /// <summary>
        /// Main method to pick up the next item in the in queue.
        /// </summary>
        /// <param name="Result">The next item in the queue</param>
        /// <returns>Whether retrieving the next item was successful.</returns>
        public bool GetNext(out object Result)
        {
            bool success = false;
            object result = null;

            lock (this)
            {
                if (MaxItems == 0 || CountInput < MaxItems)
                {
                    success = workflow.Queues[InQueue].TryDequeue(out result);
                    if (success)
                        CountInput++;
                }
            }

            Result = result;
            return success;
        }

        /// <summary>
        /// The tool for each runspace of the worker to signal it is done.
        /// Any concluding post-processing is done here, once the last runspace calls it.
        /// </summary>
        public void SignalEnd()
        {
            bool terminate = false;
            lock (this)
            {
                Interlocked.Increment(ref _CountDone);
                if (_CountDone < Count)
                    terminate = true;
            }
            if (terminate)
                return;

            // Seal the out queue if desired, ensuring subsequent workers know not to expect further input
            if (CloseOutQueue)
                workflow.CloseQueue(OutQueue);
            if (null != QueuesToClose)
                foreach (string queue in QueuesToClose)
                    workflow.CloseQueue(queue);
        }
        private int _CountDone = 0;

        /// <summary>
        /// The text form of the current worker
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            return Name;
        }

        private void AssertFunctionSafety()
        {
            foreach (string name in Functions.Keys)
                if (((PsfScriptBlock)Functions[name]).LanguageMode != PSLanguageMode.FullLanguage)
                    throw new PSSecurityException($"Cannot define function {name}: The code provided is not trusted!");
            foreach (string name in workflow.Functions.Keys)
                if (((PsfScriptBlock)workflow.Functions[name]).LanguageMode != PSLanguageMode.FullLanguage)
                    throw new PSSecurityException($"Cannot define function {name}: The code provided is not trusted!");
        }

		/// <summary>
		/// Add an error with a target to the errors queue
		/// </summary>
		/// <param name="Error">The error that happened</param>
		/// <param name="Target">The target that was being processed as the error happened</param>
		public void AddError(ErrorRecord Error, object Target)
		{
			Errors.Enqueue(new RSWorkerError(this, Error, Target));
		}
    }
}
