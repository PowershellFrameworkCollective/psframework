using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Something went wrong.
    /// </summary>
    public class RSWorkerError
    {
        /// <summary>
        /// The worker that failed
        /// </summary>
        public readonly RSWorker Worker;

        /// <summary>
        /// The actual error that happened
        /// </summary>
        public readonly ErrorRecord Error;

        /// <summary>
        /// When did it happen
        /// </summary>
        public readonly DateTime Timestamp;

        /// <summary>
        /// On what runspace did it fail
        /// </summary>
        public readonly Guid Runspace;

        /// <summary>
        /// Create a new error object for tracking purposes.
        /// </summary>
        /// <param name="Worker">The worker that failed</param>
        /// <param name="Error">The error that happened</param>
        public RSWorkerError(RSWorker Worker, ErrorRecord Error)
        {
            this.Worker = Worker;
            this.Error = Error;
            Timestamp = DateTime.Now;
            Runspace = System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId;
        }

        /// <summary>
        /// Text representation of what went wrong
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            return $"[{Worker}] {Error}";
        }
    }
}
