using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// An individual task executed in the runspace pool of its hosting RunspaceWrapper
    /// </summary>
    public class RunspaceTask : IDisposable
    {
        /// <summary>
        /// The item to process in this task
        /// </summary>
        public object InputObject;

        /// <summary>
        /// Whether the task has completed successfully
        /// </summary>
        public bool IsCompleted
        {
            get
            {
                if (null == Status)
                    return false;
                return Status.IsCompleted;
            }
        }

        internal RunspaceWrapper Host;

        private bool started;
        private PowerShell Runtime;
        private IAsyncResult Status;

        private string _CodeWrapper = @"
param ($____PSF_Code, $____PSF_Item)
([PSFramework.Utility.PsfScriptBlock]$____PSF_Code).InvokeEx($false, $____PSF_Item, $____PSF_Item, $null, $true, $true, $____PSF_Item)
";
        
        /// <summary>
        /// Create a new runspace task. If the host has already stared execution, it is immediately queued for execution.
        /// </summary>
        /// <param name="Host">The hosting RunspaceWrapper</param>
        /// <param name="InputObject">The item to process in this task</param>
        public RunspaceTask(RunspaceWrapper Host, object InputObject)
        {
            this.Host = Host;
            this.InputObject = InputObject;
            Host.CountTotal++;

            if (Host.IsRunning)
                Start();
        }

        /// <summary>
        /// If the task is complete, collect results and direct the streams. Do nothing if not complete yet.
        /// Delists itself from the hosting RunspaceWrapper, if completed.
        /// </summary>
        /// <param name="Command">The command runtime to whose streams to write the results</param>
        /// <param name="NoStreams">Do not write to additional streams</param>
        /// <returns>Whether it successfully collected the results</returns>
        public bool TryCollect(Cmdlet Command, bool NoStreams = false)
        {
            if (!IsCompleted)
                return false;

            PSDataCollection<PSObject> result = Runtime.EndInvoke(Status);
            if (NoStreams)
            {
                Kill();
                Command.WriteObject(result, true);
                return true;
            }

#if PS4
#else
            foreach (InformationRecord info in Runtime.Streams.Information)
                Command.WriteInformation(info);
#endif
            foreach (VerboseRecord info in Runtime.Streams.Verbose)
                Command.WriteVerbose(info.Message);
            foreach (WarningRecord warning in Runtime.Streams.Warning)
                Command.WriteWarning(warning.Message);
            try
            {
                foreach (ErrorRecord error in Runtime.Streams.Error)
                {
                    try { Command.WriteError(((RuntimeException)error.Exception.InnerException).ErrorRecord); }
                    catch { Command.WriteError(error); }
                }
            }
            finally
            {
                Kill();
            }

            Command.WriteObject(result, true);
            return true;
        }

        /// <summary>
        /// Wait until the task completes, then get the full result with all stream information
        /// </summary>
        /// <returns>A result object, containing output and streams</returns>
        /// <exception cref="InvalidOperationException">Don't try to collect results before starting the task</exception>
        public RunspaceResult CollectResult()
        {
            if (null == Runtime && null == Status)
                throw new InvalidOperationException("Task has not been started yet!");

            PSDataCollection<PSObject> result = Runtime.EndInvoke(Status);
            RunspaceResult resultObj = new RunspaceResult(InputObject, result, Runtime.Streams);

            Kill();

            return resultObj;
        }

        /// <summary>
        /// Wait until the task completes, then get the output
        /// </summary>
        /// <returns>All output results of the task</returns>
        /// <exception cref="InvalidOperationException">Don't try to collect results before starting the task</exception>
        public PSDataCollection<PSObject> Collect()
        {
            if (null == Runtime && null == Status)
                throw new InvalidOperationException("Task has not been started yet!");

            PSDataCollection<PSObject> result = Runtime.EndInvoke(Status);

            Kill();

            return result;
        }

        /// <summary>
        /// Wait until the task completes, then collect results and direct the streams.
        /// </summary>
        /// <param name="Command">The command runtime to whose streams to write the results</param>
        /// <param name="NoStreams">hether to NOT write to the different streams.</param>
        /// <exception cref="InvalidOperationException">Don't try to collect results before starting the task</exception>
        public void Collect(Cmdlet Command, bool NoStreams = false)
        {
            if (null == Runtime && null == Status)
                throw new InvalidOperationException("Task has not been started yet!");

            PSDataCollection<PSObject> result = Runtime.EndInvoke(Status);
            if (NoStreams)
            {
                Kill();
                Command.WriteObject(result, true);
                return;
            }


#if PS4
#else
            foreach (InformationRecord info in Runtime.Streams.Information)
                Command.WriteInformation(info);
#endif
            foreach (VerboseRecord info in Runtime.Streams.Verbose)
                Command.WriteVerbose(info.Message);
            foreach (WarningRecord warning in Runtime.Streams.Warning)
                Command.WriteWarning(warning.Message);
            try
            {
                foreach (ErrorRecord error in Runtime.Streams.Error)
                {
                    try { Command.WriteError(((RuntimeException)error.Exception.InnerException).ErrorRecord); }
                    catch { Command.WriteError(error); }
                }
            }
            finally
            {
                Kill();
            }

            Command.WriteObject(result, true);
        }

        /// <summary>
        /// Start this task, queueing the code as a runspace in the runspace pool for execution
        /// </summary>
        /// <exception cref="InvalidOperationException">If the runspacepool of the hosting RunspaceWrapper has not been opened yet, we cannot start yet</exception>
        public void Start()
        {
            if (started)
                return;
            if (!Host.IsRunning)
                throw new InvalidOperationException("Runspace Pool not opened yet!");

            Runtime = PowerShell.Create();
            Runtime.RunspacePool = Host.Pool;

            Runtime.AddScript(_CodeWrapper)
                .AddParameter("____PSF_Code", Host.Code)
                .AddParameter("____PSF_Item", InputObject);
            Status = Runtime.BeginInvoke();

            started = true;
        }

        /// <summary>
        /// Cancel and destroy this task.
        /// </summary>
        public void Kill()
        {
            if (Runtime != null)
            {
                if (Runtime.Runspace != null)
                    Runtime.Runspace.Dispose();
                Runtime.Dispose();
            }
                
            Host.Tasks.Remove(this);
        }

        /// <summary>
        /// Clean up this object
        /// </summary>
        public void Dispose()
        {
            Kill();
        }
    }
}
