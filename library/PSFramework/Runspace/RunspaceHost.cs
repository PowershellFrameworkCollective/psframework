using System;
using System.Collections.Concurrent;
using System.Collections.Generic;

namespace PSFramework.Runspace
{
    /// <summary>
    /// Provides hosting for all registered runspaces
    /// </summary>
    public static class RunspaceHost
    {
        /// <summary>
        /// The number of seconds before a Stop command is interrupted and instead the runspace is gracelessly shut down.
        /// </summary>
        public static int StopTimeoutSeconds = 30;

        /// <summary>
        /// The dictionary containing the definitive list of unique Runspace
        /// </summary>
        public static ConcurrentDictionary<string, RunspaceContainer> Runspaces = new ConcurrentDictionary<string, RunspaceContainer>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// List of all runspace bound values in use
        /// </summary>
        internal static List<RunspaceBoundValue> _RunspaceBoundValues
        {
            get
            {
                lock (_runspaceBoundValuesLock)
                    return _runspaceBoundValues;
            }
        }
        private static List<RunspaceBoundValue> _runspaceBoundValues = new List<RunspaceBoundValue>();
        private static readonly object _runspaceBoundValuesLock = new object();
    }
}
