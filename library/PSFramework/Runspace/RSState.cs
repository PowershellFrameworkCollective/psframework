using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// The state of a worker
    /// </summary>
    public enum RSState
    {
        /// <summary>
        /// The worker has yet to be configured to run
        /// </summary>
        Pending = 1,

        /// <summary>
        /// The worker is currently starting up
        /// </summary>
        Starting = 2,

        /// <summary>
        /// The worker is busy doing its job
        /// </summary>
        Running = 3,

        /// <summary>
        /// The worker is in the process of shutting down
        /// </summary>
        Stopping = 4,

        /// <summary>
        /// The worker has completed its shutdown
        /// </summary>
        Stopped = 5,

        /// <summary>
        /// The worker failed otherwise. Check the errors.
        /// </summary>
        Failed = 6
    }
}
