using PSFramework.Extension;
using PSFramework.Utility;
using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Text.RegularExpressions;

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
        /// When enabled, do not filter based on user input.
        /// </summary>
        public bool DoNotFilter;

        private int _MaxResults;
        /// <summary>
        /// Maximum number of results to show when tab-completing.
        /// </summary>
        public int MaxResults
        {
            get
            {
                if (_MaxResults > 0)
                    return _MaxResults;
                return TabExpansionHost.MaxResults;
            }
            set { _MaxResults = value; }
        }

        /// <summary>
        /// If true: Match input against any part of the options, not just the beginning
        /// </summary>
        public bool MatchAnywhere
        {
            set { _MatchAnywhere = value; }
            get
            {
                if (null != _MatchAnywhere)
                    return (bool)_MatchAnywhere;
                return TabExpansionHost.MatchAnywhere;
            }
        }
        private Nullable<bool> _MatchAnywhere;

        /// <summary>
        /// If true: Wrap all results into quotes, not just those with whitespace
        /// </summary>
        public bool AlwaysQuote
        {
            set { _AlwaysQuote = value; }
            get
            {
                if (null != _AlwaysQuote)
                    return (bool)_AlwaysQuote;
                return TabExpansionHost.AlwaysQuote;
            }
        }
        private Nullable<bool> _AlwaysQuote;

        /// <summary>
        /// If true: Apply FuzzyMatching to the legal completions, not just direct word matching.
        /// </summary>
        public bool FuzzyMatch
        {
            set { _FuzzyMatch = value; }
            get
            {
                if (null != _FuzzyMatch)
                    return (bool)_FuzzyMatch;
                return TabExpansionHost.FuzzyMatch;
            }
        }
        private Nullable<bool> _FuzzyMatch;

        /// <summary>
        /// If true: Completion results will not be sorted by name.
        /// </summary>
        public bool DontSort;

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

        /// <summary>
        /// Returns the matching pattern applied against the list of completion values.
        /// </summary>
        /// <param name="WordToComplete">What the user typed so far</param>
        /// <returns>The resolved pattern to match with</returns>
        public string GetPattern(string WordToComplete)
        {
            if (DoNotFilter)
                return ".*";

            StringBuilder stringBuilder = new StringBuilder();
            if (!MatchAnywhere && !FuzzyMatch)
                stringBuilder.Append("^['\"]{0,1}");

            string escaped = Regex.Escape(WordToComplete.Trim("\"'".ToCharArray()));

            if (!FuzzyMatch)
                stringBuilder.Append(Regex.Escape(WordToComplete.Trim("\"'".ToCharArray())));
            else
            {
                foreach (char character in WordToComplete.Trim("\"'".ToCharArray()).ToCharArray())
                {
                    stringBuilder.Append(Regex.Escape(character.ToString()));
                    stringBuilder.Append(".*");
                }
            }

            return stringBuilder.ToString();
        }

        #region Trainable
        private ConcurrentDictionary<string, Hashtable> _Trained = new ConcurrentDictionary<string, Hashtable>(StringComparer.InvariantCultureIgnoreCase);
        /// <summary>
        /// The trained values for the current completion scriptblock.
        /// </summary>
        public Hashtable[] Trained { get => _Trained.Values.ToArray(); }

        /// <summary>
        /// Whether this completion should automatically be trained with values provided to parameters
        /// </summary>
        public bool AutoTraining;

        /// <summary>
        /// Add a completion option to the list of trained completions.
        /// </summary>
        /// <param name="Text">The value to offer for completion</param>
        public void AddTraining(string Text)
        {
            Hashtable result = new Hashtable(StringComparer.InvariantCultureIgnoreCase);
            result["Text"] = Text;
            _Trained[Text] = result;
        }
        /// <summary>
        /// Add a completion option to the list of trained completions.
        /// </summary>
        /// <param name="Data">A hashtable with the completion data to add. Must at least contain a "Text" node.</param>
        /// <exception cref="ArgumentException">An invalid hashtable, not containing a key named "Text" will cause an argument exception</exception>
        public void AddTraining(Hashtable Data)
        {
            if (Data == null || !Data.ContainsKey("Text") || Data["Text"] == null)
                throw new ArgumentException("Invalid Hashtable, does not contain the required 'Text' key!");
            _Trained[Data["Text"].ToString()] = Data;
        }

        /// <summary>
        /// Remove a previously provided completion value.
        /// </summary>
        /// <param name="Text">The text value to no longer complete.</param>
        public void RemoveTraining(string Text)
        {
            Hashtable temp;
            _Trained.TryRemove(Text, out temp);
        }

        /// <summary>
        /// Remove a previously provided completion value.
        /// </summary>
        /// <param name="Data">Hashtable containing the completion to no longer offer.</param>
        public void RemoveTraining(Hashtable Data)
        {
            if (Data == null || !Data.ContainsKey("Text") || Data["Text"] == null)
                return;
            Hashtable temp;
            _Trained.TryRemove(Data["Text"].ToString(), out temp);
        }
        #endregion Trainable
    }
}
