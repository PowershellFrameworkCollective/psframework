using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using PSFramework.Parameter;

namespace PSFramework.TabExpansion
{
    /// <summary>
    /// Class that handles the static fields supporting the ÜSFramework TabExpansion implementation
    /// </summary>
    public static class TabExpansionHost
    {
        #region State information
        /// <summary>
        /// Field containing the scripts that were registered.
        /// </summary>
        public static ConcurrentDictionary<string, ScriptContainer> Scripts = new ConcurrentDictionary<string, ScriptContainer>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The cache used by scripts utilizing TabExpansionPlusPlus for PSFramework
        /// </summary>
        public static Hashtable Cache
        {
            get
            {
                lock(_CacheLock)
                    return _Cache;
            }
            set
            {
                lock(_CacheLock)
                    _Cache = value;
            }
        }
        private static Hashtable _Cache = new Hashtable(StringComparer.InvariantCultureIgnoreCase);
        private static readonly object _CacheLock = new object();
        #endregion State information

        #region Settings
        /// <summary>
        /// Whether PSFramework completion should by default match type text to anywhere in the included/valid options' text, not just from the beginning.
        /// </summary>
        public static bool MatchAnywhere;

        /// <summary>
        /// Whether PSFramework completion should always wrap quotes around the completion text, even if there is no whitespace.
        /// </summary>
        public static bool AlwaysQuote;

        /// <summary>
        /// Whether PSFramework completion should use fuzzy-matching when matching completion values with the already typed text.
        /// </summary>
        public static bool FuzzyMatch;
        #endregion Settings

        #region Public logic access
        /// <summary>
        /// Registers a new completion scriptblock
        /// </summary>
        /// <param name="Name">The name of the completion scriptblock</param>
        /// <param name="ScriptBlock">The scriptblock that will provide completion data</param>
        /// <param name="Mode">What completion mode to use</param>
        /// <param name="CacheDuration">How long the gathered pieces of data remain valid.</param>
        /// <param name="Global">Whether to globalize scriptblocks prior to invocation.</param>
        public static void RegisterCompletion(string Name, ScriptBlock ScriptBlock, TeppScriptMode Mode, TimeSpanParameter CacheDuration, bool Global)
        {
            ScriptContainer script = new ScriptContainer();
            script.Name = Name;
            script.LastDuration = new TimeSpan(-1);
            script.LastResultsValidity = CacheDuration;
            script.Global = Global;

            TeppScriptMode effectiveMode = Mode;
            if (effectiveMode == TeppScriptMode.Auto)
            {
                effectiveMode = TeppScriptMode.Full;
                if (((ScriptBlock.Ast as ScriptBlockAst) != null) && ((ScriptBlockAst)ScriptBlock.Ast).ParamBlock == null)
                    effectiveMode = TeppScriptMode.Simple;
            }

            if (effectiveMode == TeppScriptMode.Full)
                script.ScriptBlock = ScriptBlock;
            else
            {
                script.ScriptBlock = ScriptBlock.Create(SimpleCompletionScript.Replace("<name>", Name));
                script.InnerScriptBlock = ScriptBlock;
            }

            ScriptContainer oldScript;
            Scripts.TryGetValue(Name, out oldScript);
            Scripts[Name] = script;
            if (oldScript != null && oldScript.Trained.Length > 0)
                foreach (Hashtable training in oldScript.Trained)
                    script.AddTraining(training);
        }

        /// <summary>
        /// Registers a new completion scriptblock
        /// </summary>
        /// <param name="Name">The name of the completion scriptblock</param>
        /// <param name="ScriptBlock">The scriptblock that will provide completion data</param>
        /// <param name="Mode">What completion mode to use</param>
        /// <param name="CacheDuration">How long the gathered pieces of data remain valid.</param>
        /// <param name="Global">Whether to globalize scriptblocks prior to invocation.</param>
        /// <param name="PassThru">Parameter is ignored. Needed to have a second signature that returns the script container.</param>
        public static ScriptContainer RegisterCompletion(string Name, ScriptBlock ScriptBlock, TeppScriptMode Mode, TimeSpanParameter CacheDuration, bool Global, bool PassThru)
        {
            RegisterCompletion(Name, ScriptBlock, Mode, CacheDuration, Global);
            return Scripts[Name];
        }

        /// <summary>
        /// The script used for providing tabcompletion for completers using the simplified notation.
        /// </summary>
        public static string SimpleCompletionScript;
        #endregion Public logic access

        #region Resources for individual tab completions
        /// <summary>
        /// Dictionary containing a list of hashtables to explicitly add properties when completing for specific output types.
        /// Entries must have three properties:
        /// - Name (Name of Property)
        /// - Type (Type, not Typename, of the property. May be empty)
        /// - TypeKnown (Boolean, whether the type is known)
        /// Used by the Tab Completion: PSFramework-Input-ObjectProperty
        /// </summary>
        public static ConcurrentDictionary<string, object[]> InputCompletionTypeData = new ConcurrentDictionary<string, object[]>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Dictionary containing a list of hashtables to explicitly add properties when completing for specific commands
        /// Entries must have three properties:
        /// - Name (Name of Property)
        /// - Type (Type, not Typename, of the property. May be empty)
        /// - TypeKnown (Boolean, whether the type is known)
        /// Used by the Tab Completion: PSFramework-Input-ObjectProperty
        /// </summary>
        public static ConcurrentDictionary<string, object[]> InputCompletionCommandData = new ConcurrentDictionary<string, object[]>(StringComparer.InvariantCultureIgnoreCase);
        #endregion Resources for individual tab completions
    }
}
