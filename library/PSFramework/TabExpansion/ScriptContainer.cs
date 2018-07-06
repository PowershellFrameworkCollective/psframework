using System;
using System.Collections.Generic;
using System.Management.Automation;

namespace PSFramework.TabExpansion
{
    /// <summary>
    /// Regular container to store scripts in, that are used in TEPP
    /// </summary>
    public class ScriptContainer
    {
        /// <summary>
        /// The name of the scriptblock
        /// </summary>
        public string Name;

        /// <summary>
        /// The scriptblock doing the logic
        /// </summary>
        public ScriptBlock ScriptBlock;

        /// <summary>
        /// The last time the scriptblock was called. Must be updated by the scriptblock itself
        /// </summary>
        public DateTime LastExecution;

        /// <summary>
        /// The time it took to run the last time
        /// </summary>
        public TimeSpan LastDuration;

        /// <summary>
        /// Scriptblock for users using simple-TEPP acceleration
        /// </summary>
        public ScriptBlock InnerScriptBlock;

        /// <summary>
        /// THe errors that occured during scriptblock execution.
        /// </summary>
        public Utility.LimitedConcurrentQueue<ErrorRecord> ErrorRecords = new Utility.LimitedConcurrentQueue<ErrorRecord>(1024);

        /// <summary>
        /// The values the last search returned
        /// </summary>
        public string[] LastResult;

        /// <summary>
        /// How long are previous values valid, before a new execution becomes necessary.
        /// </summary>
        public TimeSpan LastResultsValidity = new TimeSpan(0);

        /// <summary>
        /// Returns whether a new refresh of tab completion should be executed.
        /// </summary>
        bool ShouldExecute
        {
            get
            {
                return LastExecution.Add(LastResultsValidity) < DateTime.Now;
            }
        }
    }
}
