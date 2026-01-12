using PSFramework.Utility;
using System;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Class that contains the logic necessary to manage a unique runspace
    /// </summary>
    public class RunspaceContainer
    {
        private PowerShell Runspace;

        /// <summary>
        /// The Generation of the Managed Runspace, determining the featureset used by it.
        /// </summary>
        public int Generation { get; internal set; }

        /// <summary>
        /// The name of the runspace.
        /// </summary>
        public readonly string Name;

        /// <summary>
        /// The Guid of the running Runspace
        /// </summary>
        public Guid RunspaceGuid
        {
            get { return Runspace.Runspace.InstanceId; }
        }

        #region Generation 1
        /// <summary>
        /// The Code that will be used when running the runspace.
        /// </summary>
        public ScriptBlock Script { get; private set; }

        /// <summary>
        /// Sets the script to execute in the runspace. Will NOT take immediate effect. Only after restarting the runspace will it be used.
        /// </summary>
        /// <param name="Script">The scriptblock to execute</param>
        public void SetScript(ScriptBlock Script)
        {
            this.Script = Script;
        }

        /// <summary>
        /// Creates a new Gen 1 runspace container with the basic information needed
        /// </summary>
        /// <param name="Name">The name of the Runspace</param>
        /// <param name="Script">The code using the runspace logic</param>
        public RunspaceContainer(string Name, ScriptBlock Script)
        {
            this.Name = Name.ToLower();
            this.Script = Script;
            Generation = 1;
        }
        #endregion Generation 1

        #region Generation 2
        /// <summary>
        /// The initialization code of the runspace, executed in the global scope.
        /// </summary>
        public ScriptBlock Begin { get; internal set; }
        /// <summary>
        /// The execution code of the runspace, will be called repeatedly over the time of the runspace.
        /// </summary>
        public ScriptBlock Process { get; internal set; }
        /// <summary>
        /// The finalization code of the runspace, will be called once when closing out the runspace.
        /// </summary>
        public ScriptBlock End { get; internal set; }

        /// <summary>
        /// Creates a new Gen 2 runspace container with the basic information needed
        /// </summary>
        /// <param name="Name">The name of the Runspace</param>
        /// <param name="Begin">The initialization code of the runspace, executed in the global scope.</param>
        /// <param name="Process">The execution code of the runspace, will be called repeatedly over the time of the runspace.</param>
        /// <param name="End">The finalization code of the runspace, will be called once when closing out the runspace.</param>
        public RunspaceContainer(string Name, ScriptBlock Begin, ScriptBlock Process, ScriptBlock End)
        {
            this.Name = Name.ToLower();
            this.Begin = Begin;
            this.Process = Process;
            this.End = End;
            Script = RunspaceHost.ManagedRunspaceCodeGen2;
            Generation = 2;
        }

        /// <summary>
        /// Initialize a runtime reference for the current managed runspace
        /// </summary>
        /// <returns>A Runtime reference, including the code for all three phases of a Gen 2 Managed Runspace</returns>
        public RunspaceRuntime GetRuntime()
        {
            return new RunspaceRuntime(Begin, Process, End, Errors, this);
        }
        #endregion Generation 2

        #region Runtime
        /// <summary>
        /// The state the runspace currently is in.
        /// </summary>
        public PsfRunspaceState State
        {
            get { return _State; }
        }
        private PsfRunspaceState _State = PsfRunspaceState.Stopped;

        /// <summary>
        /// The last 50 errors that happened in the runspace
        /// </summary>
        public LimitedConcurrentQueue<ErrorRecord> Errors = new LimitedConcurrentQueue<ErrorRecord>(50);

        /// <summary>
        /// Starts the Runspace.
        /// </summary>
        public void Start()
        {
            if ((Runspace != null) && ((State == PsfRunspaceState.Stopped) || (State == PsfRunspaceState.Failed)))
            {
                Kill();
            }

            if (Runspace == null)
            {
                Runspace = PowerShell.Create();
                try { SetName(Runspace.Runspace); }
                catch { }
                Runspace.AddScript(Script.ToString()).AddArgument(this);
                _State = PsfRunspaceState.Running;
                try { Runspace.BeginInvoke(); }
                catch (Exception e) {
                    Errors.TryAdd(new ErrorRecord(e, "RunspaceEngineFail", ErrorCategory.OpenError, null));
                    _State = PsfRunspaceState.Failed;
                }
            }
        }

        /// <summary>
        /// Sets the name on a runspace. This WILL FAIL for PowerShell v3!
        /// </summary>
        /// <param name="Runspace">The runspace to be named</param>
        private void SetName(System.Management.Automation.Runspaces.Runspace Runspace)
        {
            Runspace.Name = Name;
        }

        /// <summary>
        /// Gracefully stops the Runspace
        /// </summary>
        public void Stop()
        {
            _State = PsfRunspaceState.Stopping;

            int i = 0;

            // Wait up to the limit for the running script to notice and kill itself
            while ((Runspace != null) && (Runspace.Runspace != null) && (Runspace.Runspace.RunspaceAvailability == RunspaceAvailability.Busy) && (i < (10 * RunspaceHost.StopTimeoutSeconds)))
            {
                i++;
                Thread.Sleep(100);
            }
            
            Kill();
        }

        /// <summary>
        /// Very ungracefully kills the runspace. Use only in the most dire emergency.
        /// </summary>
        public void Kill()
        {
            if (Runspace != null)
            {
                try { Runspace.Runspace.Close(); }
                catch { }
                if (Runspace != null)
                    Runspace.Dispose();
                Runspace = null;
            }

            _State = PsfRunspaceState.Stopped;
        }

        /// <summary>
        /// Signals the registered runspace has stopped execution
        /// </summary>
        public void SignalStopped()
        {
            if (_State != PsfRunspaceState.Failed)
                _State = PsfRunspaceState.Stopped;
        }

        /// <summary>
        /// Signals the registered runspace has failed badly and error logs should be checked.
        /// </summary>
        public void SignalFailed()
        {
            _State = PsfRunspaceState.Failed;
        }
        #endregion Runtime
    }
}
