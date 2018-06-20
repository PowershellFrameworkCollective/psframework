using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

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
        #endregion Core metadata

        #region Message filtering
        private List<string> _IncludeModules = new List<string>();
        /// <summary>
        /// List of modules to include in the logging. Only messages generated from these modules will be considered by the provider
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
        /// List of modules to exclude in the logging. Messages generated from these modules will be ignored by this provider.
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

        private List<string> _IncludeTags = new List<string>();
        /// <summary>
        /// List of tags to include. Only messages with these tags will be considered by this provider.
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
        /// List of tags to exclude. Messages with these tags will be ignored by this provider.
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

        /// <summary>
        /// Tests whether a log entry applies to the provider
        /// </summary>
        /// <param name="Entry">The Entry to validate</param>
        /// <returns>Whether it applies</returns>
        public bool MessageApplies(Message.LogEntry Entry)
        {
            if ((IncludeModules.Count == 0) && (ExcludeModules.Count == 0) && (IncludeTags.Count == 0) && (ExcludeTags.Count == 0))
                return true;

            if (IncludeModules.Count > 0)
            {
                bool test = false;
                foreach (string module in IncludeModules)
                    if (Entry.ModuleName.ToLower() == module.ToLower())
                        test = true;

                if (!test)
                    return false;
            }

            foreach(string module in ExcludeModules)
                if (Entry.ModuleName.ToLower() == module.ToLower())
                    return false;

            if (IncludeTags.Count > 0)
            {
                if (IncludeTags.Except(Entry.Tags).ToList().Count == IncludeTags.Count)
                    return false;
            }

            if (ExcludeTags.Except(Entry.Tags).ToList().Count < ExcludeTags.Count)
                return false;

            return true;
        }

        /// <summary>
        /// Tests whether an error record applies to the provider
        /// </summary>
        /// <param name="Record">The error record to test</param>
        /// <returns>Whether it applies to the provider</returns>
        public bool MessageApplies(Message.PsfExceptionRecord Record)
        {
            if ((IncludeModules.Count == 0) && (ExcludeModules.Count == 0) && (IncludeTags.Count == 0) && (ExcludeTags.Count == 0))
                return true;

            if (IncludeModules.Count > 0)
            {
                bool test = false;
                foreach (string module in IncludeModules)
                    if (Record.ModuleName.ToLower() == module.ToLower())
                        test = true;

                if (!test)
                    return false;
            }

            foreach (string module in ExcludeModules)
                if (Record.ModuleName.ToLower() == module.ToLower())
                    return false;

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
        #endregion Scriptblocks Logging Execution

        #region Function Extension / Integration
        /// <summary>
        /// Script that recognizes, whether the provider has been isntalled correctly. Some providers require installation, in order to function properly.
        /// </summary>
        public ScriptBlock IsInstalledScript;

        /// <summary>
        /// Script that installs the provider
        /// </summary>
        public ScriptBlock InstallationScript;

        /// <summary>
        /// Script that generates dynamic parameters for installing the provider.
        /// </summary>
        public ScriptBlock InstallationParameters;

        /// <summary>
        /// Scriptblock that adds additional parameters as needed to the Set-PSFLoggingProvider function
        /// </summary>
        public ScriptBlock ConfigurationParameters;

        /// <summary>
        /// The configuration steps taken by the Set-PSFLoggingProvider function
        /// </summary>
        public ScriptBlock ConfigurationScript;
        #endregion Function Extension / Integration

        #region Troubleshooting / Analysis
        /// <summary>
        /// List of errors that happened on the logging runspace.
        /// </summary>
        public Stack<ErrorRecord> Errors = new Stack<ErrorRecord>();
        #endregion Troubleshooting / Analysis
    }
}
