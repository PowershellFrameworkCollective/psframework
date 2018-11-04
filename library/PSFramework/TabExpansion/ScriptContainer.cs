using System;
using System.Collections.Generic;
using System.Linq;
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
        public string[] LastResult = new string[0];

        /// <summary>
        /// How long are previous values valid, before a new execution becomes necessary.
        /// </summary>
        public TimeSpan LastResultsValidity = new TimeSpan(0);

        /// <summary>
        /// Returns whether a new refresh of tab completion should be executed.
        /// </summary>
        public bool ShouldExecute
        {
            get
            {
                return LastExecution.Add(LastResultsValidity) < DateTime.Now;
            }
        }

        /// <summary>
        /// Returns the correct results, either by executing the scriptblock or consulting the cache
        /// </summary>
        /// <returns></returns>
        public string[] Invoke()
        {
            if (!ShouldExecute)
                return LastResult;

            List<string> results = new List<string>();

            IEnumerable<CallStackFrame> _callStack = System.Management.Automation.Runspaces.Runspace.DefaultRunspace.Debugger.GetCallStack();
            CallStackFrame callerFrame = null;
            if (_callStack.Count() > 0)
                callerFrame = _callStack.First();

            ScriptBlock scriptBlock = ScriptBlock.Create(ScriptBlock.ToString());
            foreach (PSObject item in scriptBlock.Invoke(callerFrame.InvocationInfo.MyCommand.Name, "", "", null, callerFrame.InvocationInfo.BoundParameters))
                results.Add((string)item.Properties["CompletionText"].Value);

            return results.ToArray();
        }
    }
}
