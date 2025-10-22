using PSFramework.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// The result of a runspace task
    /// </summary>
    public class RunspaceResult
    {
        /// <summary>
        /// The object that triggered the task
        /// </summary>
        public object InputObject;
        /// <summary>
        /// All output
        /// </summary>
        public List<PSObject> Output = new List<PSObject>();
        /// <summary>
        /// All Information Messages
        /// </summary>
        public List<object> Information = new List<object>();
        /// <summary>
        /// All verbose messages
        /// </summary>
        public List<VerboseRecord> Verbose = new List<VerboseRecord>();
        /// <summary>
        /// All warning messages
        /// </summary>
        public List<WarningRecord> Warnings = new List<WarningRecord>();
        /// <summary>
        /// All error records
        /// </summary>
        public List<ErrorRecord> Errors = new List<ErrorRecord>();

        /// <summary>
        /// Creates a result object, representing the completed result of the runspace task.
        /// </summary>
        /// <param name="InputObject">The original argument for the task</param>
        /// <param name="Output">The output result of the task</param>
        /// <param name="Streams">The streams the task sent</param>
        public RunspaceResult(object InputObject, PSDataCollection<PSObject> Output, PSDataStreams Streams)
        {
            this.InputObject = InputObject;
            if (Output.Count > 0)
                this.Output.AddRange(Output);
            if (Streams.Verbose.Count > 0)
                Verbose.AddRange(Streams.Verbose);
            if (Streams.Warning.Count > 0)
                Warnings.AddRange(Streams.Warning);
            if (Streams.Error.Count > 0)
            {
                foreach (ErrorRecord record in Streams.Error)
                {
                    try { Errors.Add(((RuntimeException)record.Exception.InnerException).ErrorRecord); }
                    catch { Errors.Add(record); }
                }
            }
#if PS4
#else
            if (Streams.Information.Count > 0)
                Information.AddRange(Streams.Information);
#endif
        }
    }
}
