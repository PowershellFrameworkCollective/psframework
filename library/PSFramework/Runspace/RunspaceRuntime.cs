using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Wrapper around the execution stages of a Generation 2 Managed Runspace
    /// </summary>
    public class RunspaceRuntime
    {
        /// <summary>
        /// Begin phase of the Managed Runspace
        /// </summary>
        public readonly PsfScriptBlock Begin;
        /// <summary>
        /// Process phase of the Managed Runspace
        /// </summary>
        public readonly PsfScriptBlock Process;
        /// <summary>
        /// End phase of the Managed Runspace
        /// </summary>
        public readonly PsfScriptBlock End;
        /// <summary>
        /// Access to the error queue of the managed runspace
        /// </summary>
        public readonly LimitedConcurrentQueue<ErrorRecord> Errors;
        /// <summary>
        /// The actual runspace container with the original task.
        /// MAY BE MODIFIED after launch, should not be used for critical lifestate data.
        /// </summary>
        public readonly RunspaceContainer Workload;

        /// <summary>
        /// Create a new Managed Runspace Runtime wrapper
        /// </summary>
        /// <param name="Begin">Begin phase of the Managed Runspace</param>
        /// <param name="Process">Process phase of the Managed Runspace</param>
        /// <param name="End">End phase of the Managed Runspace</param>
        /// <param name="Errors">Access to the error queue of the managed runspace</param>
        /// <param name="Workload">The actual runspace container with the original task.</param>
        public RunspaceRuntime(ScriptBlock Begin, ScriptBlock Process, ScriptBlock End, LimitedConcurrentQueue<ErrorRecord> Errors, RunspaceContainer Workload)
        {
            if (Begin != null)
                this.Begin = ((PsfScriptBlock)Begin).ToGlobal();
            if (Process != null)
                this.Process = ((PsfScriptBlock)Process).ToGlobal();
            if (End != null)
                this.End = ((PsfScriptBlock)End).ToGlobal();
            this.Errors = Errors;
            this.Workload = Workload;
        }
    }
}
