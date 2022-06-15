using PSFramework.Extension;
using PSFramework.Utility;
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
        /// The completion data for the values the last search returned
        /// </summary>
        public object[] LastCompletion = new object[0];

        /// <summary>
        /// How long are previous values valid, before a new execution becomes necessary.
        /// </summary>
        public TimeSpan LastResultsValidity = new TimeSpan(0);

        /// <summary>
        /// Whether to execute the scriptblock in the global scope
        /// </summary>
        public bool Global;

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

            CallStackFrame callerFrame = null;
            InvocationInfo info = null;
            try
            {
                object CurrentCommandProcessor = UtilityHost.GetPrivateProperty("CurrentCommandProcessor", UtilityHost.GetExecutionContextFromTLS());
                object CommandObject = UtilityHost.GetPrivateProperty("Command", CurrentCommandProcessor);
                info = UtilityHost.GetPublicProperty("MyInvocation", CommandObject) as InvocationInfo;
            }
            catch (Exception e)
            {
                if (PSFCore.PSFCoreHost.DebugMode)
                    PSFCore.PSFCoreHost.WriteDebug(String.Format("Script Container {0} | Error accessing Current Command Processor", Name), e);
            }

            if (info == null)
            {
                IEnumerable<CallStackFrame> _callStack = UtilityHost.Callstack;

                object errorItem = null;
                try
                {
                    if (_callStack.Count() > 0)
                        callerFrame = _callStack.Where(frame => frame.InvocationInfo != null && frame.InvocationInfo.MyCommand != null).First();
                }
                catch (Exception e) { errorItem = e; }
                if (PSFCore.PSFCoreHost.DebugMode)
                {
                    PSFCore.PSFCoreHost.WriteDebug(String.Format("Script Container {0} | Callframe selected", Name), callerFrame);
                    PSFCore.PSFCoreHost.WriteDebug(String.Format("Script Container {0} | Script Callstack", Name), new Message.CallStack(UtilityHost.Callstack));
                    if (errorItem != null)
                        PSFCore.PSFCoreHost.WriteDebug(String.Format("Script Container {0} | Error when selecting Callframe", Name), errorItem);
                }
            }
            if (info == null && callerFrame != null)
                info = callerFrame.InvocationInfo;

            object[] arguments = null;
            if (info != null)
                arguments = new object[] { info.MyCommand.Name, "", "", null, info.BoundParameters };
            else
                arguments = new object[] { "<ScriptBlock>", "", "", null, new Dictionary<string, object>(StringComparer.InvariantCultureIgnoreCase) };

            ScriptBlock tempScriptBlock = ScriptBlock;
            if (Global)
                tempScriptBlock = ScriptBlock.Clone().ToGlobal();
            
            foreach (PSObject item in tempScriptBlock.Invoke(arguments))
                results.Add((string)item.Properties["CompletionText"].Value);
            
            return results.ToArray();
        }
    }
}
