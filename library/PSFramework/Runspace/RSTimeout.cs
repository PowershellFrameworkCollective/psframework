using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    /// <summary>
    /// What kind of timeout a Runspace Workflow Work Item uses
    /// </summary>
    public enum RSTimeout
    {
        /// <summary>
        /// No timeout at all.
        /// Will keep running until completed or failed
        /// </summary>
        None,

        /// <summary>
        /// The timeout is counted from the start of the work item.
        /// </summary>
        Start,

        /// <summary>
        /// The timeout is counted from the moment of last activity
        /// </summary>
        Idle,

        /// <summary>
        /// No timeout configured at this level
        /// </summary>
        Undefined
    }
}
