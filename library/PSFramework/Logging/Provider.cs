using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using PSFramework.Utility;

namespace PSFramework.Logging
{
    /// <summary>
    /// Class containing all information/content needed for a logging provider
    /// </summary>
    public class Provider
    {
        #region Core metadata
        /// <summary>
        /// Each logging provider has a name. Make sure it's unique
        /// </summary>
        public string Name;

        /// <summary>
        /// Whether the logging provider is enabled. Only when this is set to true will the logging script execute its events.
        /// </summary>
        public bool Enabled;

        /// <summary>
        /// The provider has had its initial runtime configuration (what is stored in the BeginEvent) applied.
        /// </summary>
        public bool Initialized;

        /// <summary>
        /// Whether the provider must be installed, in order for it to be used.
        /// </summary>
        public bool InstallationOptional;

        /// <summary>
        /// The generation of the logging provider.
        /// </summary>
        public ProviderVersion ProviderVersion = ProviderVersion.Version_1;
        #endregion Core metadata

        #region Message filtering
        private List<string> _IncludeModules = new List<string>();
        /// <summary>
        /// List of modules to include in the logging. Only messages generated from these modules will be considered by the provider instance.
        /// </summary>
        public List<string> IncludeModules
        {
            get { return _IncludeModules; }
            set
            {
                if (value == null)
                    _IncludeModules.Clear();
                else
                    _IncludeModules = value;
            }
        }

        private List<string> _ExcludeModules = new List<string>();
        /// <summary>
        /// List of modules to exclude in the logging. Messages generated from these modules will be ignored by this provider instance.
        /// </summary>
        public List<string> ExcludeModules
        {
            get { return _ExcludeModules; }
            set
            {
                if (value == null)
                    _ExcludeModules.Clear();
                else
                    _ExcludeModules = value;
            }
        }

        private List<string> _IncludeFunctions = new List<string>();
        /// <summary>
        /// List of functions to include in the logging. Only messages generated from these functions will be considered by the provider instance.
        /// </summary>
        public List<string> IncludeFunctions
        {
            get { return _IncludeFunctions; }
            set
            {
                if (value == null)
                    _IncludeFunctions.Clear();
                else
                    _IncludeFunctions = value;
            }
        }

        private List<string> _ExcludeFunctions = new List<string>();
        /// <summary>
        /// List of functions to exclude in the logging. Messages generated from these functions will be ignored by this provider instance.
        /// </summary>
        public List<string> ExcludeFunctions
        {
            get { return _ExcludeFunctions; }
            set
            {
                if (value == null)
                    _ExcludeFunctions.Clear();
                else
                    _ExcludeFunctions = value;
            }
        }

        private List<string> _IncludeTags = new List<string>();
        /// <summary>
        /// List of tags to include. Only messages with these tags will be considered by this provider instance.
        /// </summary>
        public List<string> IncludeTags
        {
            get { return _IncludeTags; }
            set
            {
                if (value == null)
                    _IncludeTags.Clear();
                else
                    _IncludeTags = value;
            }
        }

        private List<string> _ExcludeTags = new List<string>();
        /// <summary>
        /// List of tags to exclude. Messages with these tags will be ignored by this provider instance.
        /// </summary>
        public List<string> ExcludeTags
        {
            get { return _ExcludeTags; }
            set
            {
                if (value == null)
                    _ExcludeTags.Clear();
                else
                    _ExcludeTags = value;
            }
        }

        private List<Guid> _IncludeRunspaces = new List<Guid>();
        /// <summary>
        /// List of runspaces to include. Only messages from one of these runspaces will be considered by this provider.
        /// </summary>
        public List<Guid> IncludeRunspaces
        {
            get { return _IncludeRunspaces; }
            set
            {
                if (value == null)
                    _IncludeRunspaces.Clear();
                else
                    _IncludeRunspaces = value;
            }
        }

        private List<Guid> _ExcludeRunspaces = new List<Guid>();
        /// <summary>
        /// List of runspaces to exclude. Messages from these runspaces will be ignored by this provider.
        /// </summary>
        public List<Guid> ExcludeRunspaces
        {
            get { return _ExcludeRunspaces; }
            set
            {
                if (value == null)
                    _ExcludeRunspaces.Clear();
                else
                    _ExcludeRunspaces = value;
            }
        }

        private int _MinLevel = 1;
        /// <summary>
        /// The minimum level of message to log.
        /// Note, the lower the level, the higher the priority.
        /// </summary>
        public int MinLevel
        {
            get { return _MinLevel; }
            set
            {
                if (value < 1)
                    _MinLevel = 1;
                else if (value > 9)
                    _MinLevel = 9;
                else
                    _MinLevel = value;
            }
        }

        private int _MaxLevel = 9;
        /// <summary>
        /// The maximum level of message to log.
        /// Note, the lower the level, the higher the priority.
        /// </summary>
        public int MaxLevel
        {
            get { return _MaxLevel; }
            set
            {
                if (value < 1)
                    _MaxLevel = 1;
                else if (value > 9)
                    _MaxLevel = 9;
                else
                    _MaxLevel = value;
            }
        }

        /// <summary>
        /// Whether to include warning messages in the log
        /// </summary>
        public bool IncludeWarning = true;

        /// <summary>
        /// Tests whether a log entry applies to the provider instance
        /// </summary>
        /// <param name="Entry">The Entry to validate</param>
        /// <returns>Whether it applies</returns>
        public bool MessageApplies(Message.LogEntry Entry)
        {
            // Level
            if (!IncludeWarning && (Entry.Level == Message.MessageLevel.Warning))
                return false;
            if (((_MinLevel != 1) || (_MaxLevel != 9)) && (Entry.Level != Message.MessageLevel.Warning))
            {
                if (Entry.Level < (Message.MessageLevel)_MinLevel)
                    return false;
                if (Entry.Level > (Message.MessageLevel)_MaxLevel)
                    return false;
            }

            // Modules
            if (IncludeModules.Count > 0)
            {
                bool test = false;
                foreach (string module in IncludeModules)
                    if (string.Equals(Entry.ModuleName, module, StringComparison.InvariantCultureIgnoreCase))
                        test = true;

                if (!test)
                    return false;
            }

            foreach (string module in ExcludeModules)
                if (string.Equals(Entry.ModuleName, module, StringComparison.InvariantCultureIgnoreCase))
                    return false;

            // Runspaces
            if (IncludeRunspaces.Count > 0 && !IncludeRunspaces.Contains(Entry.Runspace))
                return false;
            if (ExcludeRunspaces.Contains(Entry.Runspace))
                return false;

            // Functions
            if (IncludeFunctions.Count > 0)
            {
                bool test = false;
                foreach (string function in IncludeFunctions)
                    if (UtilityHost.IsLike(Entry.FunctionName, function))
                        test = true;

                if (!test)
                    return false;
            }

            foreach (string function in ExcludeFunctions)
                if (UtilityHost.IsLike(Entry.FunctionName, function))
                    return false;

            // Tags
            if (IncludeTags.Count > 0)
            {
                if (IncludeTags.Except(Entry.Tags, StringComparer.InvariantCultureIgnoreCase).ToList().Count == IncludeTags.Count)
                    return false;
            }

            if (ExcludeTags.Except(Entry.Tags, StringComparer.InvariantCultureIgnoreCase).ToList().Count < ExcludeTags.Count)
                return false;

            return true;
        }

        /// <summary>
        /// Tests whether an error record applies to the provider instance
        /// </summary>
        /// <param name="Record">The error record to test</param>
        /// <returns>Whether it applies to the provider instance</returns>
        public bool MessageApplies(Message.PsfExceptionRecord Record)
        {
            // Modules
            if (IncludeModules.Count > 0)
            {
                bool test = false;
                foreach (string module in IncludeModules)
                    if (string.Equals(Record.ModuleName, module, StringComparison.InvariantCultureIgnoreCase))
                        test = true;

                if (!test)
                    return false;
            }

            foreach (string module in ExcludeModules)
                if (string.Equals(Record.ModuleName, module, StringComparison.InvariantCultureIgnoreCase))
                    return false;

            // Runspaces
            if (IncludeRunspaces.Count > 0 && !IncludeRunspaces.Contains(Record.Runspace))
                return false;
            if (ExcludeRunspaces.Contains(Record.Runspace))
                return false;

            // Functions
            if (IncludeFunctions.Count > 0)
            {
                bool test = false;
                foreach (string function in IncludeFunctions)
                    if (UtilityHost.IsLike(Record.FunctionName, function))
                        test = true;

                if (!test)
                    return false;
            }

            foreach (string function in ExcludeFunctions)
                if (UtilityHost.IsLike(Record.FunctionName, function))
                    return false;

            // Tags
            if (IncludeTags.Count > 0)
            {
                if (IncludeTags.Except(Record.Tags).ToList().Count == IncludeTags.Count)
                    return false;
            }

            if (ExcludeTags.Except(Record.Tags).ToList().Count < ExcludeTags.Count)
                return false;

            return true;
        }
        #endregion Message filtering

        #region Scriptblocks Logging Execution
        /// <summary>
        /// Event that is executed once per logging script execution, before logging occurs
        /// </summary>
        public ScriptBlock BeginEvent;

        /// <summary>
        /// Event that is executed each logging cycle, right before processing items.
        /// </summary>
        public ScriptBlock StartEvent;

        /// <summary>
        /// Event that is executed for each message written
        /// </summary>
        public ScriptBlock MessageEvent;

        /// <summary>
        /// Event that is executed for each error written
        /// </summary>
        public ScriptBlock ErrorEvent;

        /// <summary>
        /// Event that is executed once per logging cycle, after processing all message and error items.
        /// </summary>
        public ScriptBlock EndEvent;

        /// <summary>
        /// Final Event that is executed when stopping the logging script.
        /// </summary>
        public ScriptBlock FinalEvent;

        /// <summary>
        /// This will import the events into the current execution context, breaking runspace affinity
        /// </summary>
        public void LocalizeEvents()
        {
            UtilityHost.ImportScriptBlock(BeginEvent, true);
            UtilityHost.ImportScriptBlock(StartEvent, true);
            UtilityHost.ImportScriptBlock(MessageEvent, true);
            UtilityHost.ImportScriptBlock(ErrorEvent, true);
            UtilityHost.ImportScriptBlock(EndEvent, true);
            UtilityHost.ImportScriptBlock(FinalEvent, true);
        }
        #endregion Scriptblocks Logging Execution

        #region Function Extension / Integration
        /// <summary>
        /// Script that recognizes, whether the provider has been isntalled correctly. Some providers require installation, in order to function properly.
        /// </summary>
        public PsfScriptBlock IsInstalledScript;

        /// <summary>
        /// Script that installs the provider
        /// </summary>
        public PsfScriptBlock InstallationScript;

        /// <summary>
        /// Script that generates dynamic parameters for installing the provider.
        /// </summary>
        public PsfScriptBlock InstallationParameters;

        /// <summary>
        /// Scriptblock that adds additional parameters as needed to the Set-PSFLoggingProvider function
        /// </summary>
        public PsfScriptBlock ConfigurationParameters;

        /// <summary>
        /// The configuration steps taken by the Set-PSFLoggingProvider function
        /// </summary>
        public PsfScriptBlock ConfigurationScript;
        #endregion Function Extension / Integration

        #region Troubleshooting / Analysis
        /// <summary>
        /// List of errors that happened on the logging runspace.
        /// </summary>
        public Stack<ErrorRecord> Errors = new Stack<ErrorRecord>();
        #endregion Troubleshooting / Analysis

        /// <summary>
        /// Returns the name of the provider.
        /// </summary>
        /// <returns>Returns the name of the provider.</returns>
        public override string ToString()
        {
            return Name;
        }
    }
}
