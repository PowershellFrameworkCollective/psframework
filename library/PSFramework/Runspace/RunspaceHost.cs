using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Timers;

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
        /// The interval (in milliseonds) in which Runspace-Bound Values will be leaned up
        /// </summary>
        public static int RbvCleanupInterval
        {
            get => _RbvCleanupInterval;
            set
            {
                _RbvCleanupInterval = value;
                StopRbvTimer();
                StartRbvTimer();
            }
        }
        private static int _RbvCleanupInterval = 900000;

        /// <summary>
        /// The dictionary containing the definitive list of unique Runspace
        /// </summary>
        public static ConcurrentDictionary<string, RunspaceContainer> Runspaces = new ConcurrentDictionary<string, RunspaceContainer>(StringComparer.InvariantCultureIgnoreCase);

        #region Runspace Bound Values
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

        private static Timer _Timer;

        /// <summary>
        /// Starts the timer that in the background will periodically clean up runspace-bound variable-values that no longer have a hosting runspace.
        /// </summary>
        internal static void StartRbvTimer()
        {
            _Timer = new Timer(900000); // Every 15 minutes should suffice
            _Timer.Elapsed += CleanupRunspaceBoundVariables;
            _Timer.AutoReset = true;
            _Timer.Enabled = true;
        }

        /// <summary>
        /// Stops the timer that in the background will periodically clean up runspace-bound variable-values that no longer have a hosting runspace.
        /// Should only be called when destroying the primary runspace.
        /// </summary>
        internal static void StopRbvTimer()
        {
            _Timer.Stop();
        }

        private static void CleanupRunspaceBoundVariables(object source, ElapsedEventArgs e)
        {
            PurgeAllRunspaceBoundVariables();
        }

        /// <summary>
        /// Purge all RBVs of datasets from all expired runspaces
        /// </summary>
        public static void PurgeAllRunspaceBoundVariables()
        {
            foreach (RunspaceBoundValue value in _RunspaceBoundValues)
                value.PurgeExpired();
        }
        #endregion Runspace Bound Values

        #region Locks
        /// <summary>
        /// List of runspace locks available across the process
        /// </summary>
        private static ConcurrentDictionary<string, RunspaceLock> Locks = new ConcurrentDictionary<string, RunspaceLock>(StringComparer.InvariantCultureIgnoreCase);

        private static object _Lock = 42;
        /// <summary>
        /// Retrieve a named runspace lock, creating it first if necessary.
        /// </summary>
        /// <param name="Name">Name of the lock to create.</param>
        /// <returns>The lock object</returns>
        public static RunspaceLock GetRunspaceLock(string Name)
        {
            lock (_Lock)
            {
                if (null == Locks[Name])
                    Locks[Name] = new RunspaceLock(Name);
            }
            return Locks[Name];
        }
        #endregion Locks
    }
}
