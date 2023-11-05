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
        public int InQueueTotalItemCount => dispatcher.Queues[InQueue].TotalItemCount;

        /// <summary>
        /// Whether all items that have ever been added to the inqueue have already been processed through this worker
        /// </summary>
        public bool Completed => CountInputCompleted >= InQueueTotalItemCount;

        /// <summary>
        /// Whether the inqueue has been closed and fully processed. If so, processing can stop.
        /// </summary>
        public bool IsDone => dispatcher.Queues[InQueue].Closed && CountInputCompleted >= InQueueTotalItemCount;

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
        /// The Dispatcher owning the worker
        /// </summary>
        public RSDispatcher Dispatcher => dispatcher;

        private RunspacePool pool;
        private RSDispatcher dispatcher;
        private List<RSPowerShellWrapper> runtimes = new List<RSPowerShellWrapper>();

        /// <summary>
        /// Create a new runspace worker
        /// </summary>
        /// <param name="Name">The name of the worker</param>
        /// <param name="InQueue">Name of the input queue to use</param>
        /// <param name="OutQueue">Name of the output queue to use</param>
        /// <param name="ScriptBlock">The code that actually consumes the input</param>
        /// <param name="Dispatcher">The dispatcher object running the entire workflow.</param>
        /// <param name="Count">The number of runspaces this worker will maintain.</param>
        public RSWorker(string Name, string InQueue, string OutQueue, PsfScriptBlock ScriptBlock, RSDispatcher Dispatcher, int Count = 1)
        {
            this.Name = Name;
            this.InQueue = InQueue;
            this.OutQueue = OutQueue;
            this.ScriptBlock = ScriptBlock;
            dispatcher = Dispatcher;
            this.Count = Count;
        }

        /// <summary>
        /// Starts the worker, creating the number of runspaces configured after preparing the execution state.
        /// </summary>
        /// <exception cref="InvalidOperationException">Bad language modes or not having configured a dispatcher is a bad thing.</exception>
        /// <exception cref="ArgumentException">A Count less than 1 is implausible.</exception>
        public void Start()
        {
            if (WorkerCode.LanguageMode != PSLanguageMode.FullLanguage)
                throw new InvalidOperationException("Refusing to launch worker: The registered worker code is not trusted!");

            if (null == dispatcher)
                throw new InvalidOperationException("Runspace Dispatcher cannot be null!");

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
                localState = dispatcher.SessionState;
            if (null == localState)
                localState = InitialSessionState.CreateDefault();

            if (dispatcher.Modules.Count > 0)
                localState.ImportPSModule(dispatcher.Modules.ToArray());
            if (Modules.Count > 0)
                localState.ImportPSModule(Modules.ToArray());
            localState.ImportPSModulesFromPath(PSFCore.PSFCoreHost.ModuleRoot);

            if (dispatcher.Functions.Count > 0)
                foreach (string name in dispatcher.Functions.Keys)
                    localState.Commands.Add(new SessionStateFunctionEntry(name, dispatcher.Functions[name].ToString()));
            if (Functions.Count > 0)
                foreach (string name in Functions.Keys)
                    localState.Commands.Add(new SessionStateFunctionEntry(name, Functions[name].ToString()));

            if (dispatcher.Variables.Count > 0)
                foreach (string name in dispatcher.Variables.Keys)
                    localState.Variables.Add(new SessionStateVariableEntry(name, dispatcher.Variables[name], null));
            if (Variables.Count > 0)
                foreach (string name in Variables.Keys)
                    localState.Variables.Add(new SessionStateVariableEntry(name, Variables[name], null));
            localState.Variables.Add(new SessionStateVariableEntry("__PSF_Dispatcher", dispatcher, "PSF Runspace Dispatcher, used to manage the data transfer between workers and the state handling of the workload.", ScopedItemOptions.Constant));
            localState.Variables.Add(new SessionStateVariableEntry("__PSF_Worker", this, "PSF Worker. Represents itself in the active runspaces.", ScopedItemOptions.Constant));
            #endregion Prepare the Initial Session State

            State = RSState.Starting;

            #region Launch Runspaces
            pool = RunspaceFactory.CreateRunspacePool(localState);
            pool.SetMinRunspaces(1);
            pool.SetMaxRunspaces(Count);
            pool.Open();

            for (int i = 0; i < Count; i++)
            {
                PowerShell powershell = PowerShell.Create();
                powershell.RunspacePool = pool;
                powershell.AddScript(WorkerCode.ToString());
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
			if (null == pool)
				return;
            pool.Close();
            pool.Dispose();

            runtimes = new List<RSPowerShellWrapper>();
        }

        /// <summary>
        /// Increase the count of input items started
        /// </summary>
        public void IncrementInput()
        {
            Interlocked.Increment(ref CountInput);
            LastInput = DateTime.Now;
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
        /// The tool for each runspace of the worker to signal it is done.
        /// Any concluding post-processing is done here, once the last runspace calls it.
        /// </summary>
        public void SignalEnd()
        {
            bool terminate = false;
            lock (this)
            {
                _CountDone++;
                if (_CountDone < Count)
                    terminate = true;
            }
            if (terminate)
                return;

            // Seal the out queue if desired, ensuring subsequent workers know not to expect further input
            if (CloseOutQueue)
                dispatcher.CloseQueue(OutQueue);
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
            foreach (string name in dispatcher.Functions.Keys)
                if (((PsfScriptBlock)dispatcher.Functions[name]).LanguageMode != PSLanguageMode.FullLanguage)
                    throw new PSSecurityException($"Cannot define function {name}: The code provided is not trusted!");
        }
    }
}
