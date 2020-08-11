using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using PSFramework.Utility;

namespace PSFramework.Logging
{
    /// <summary>
    /// Active instance of a logging provider
    /// </summary>
    public class ProviderInstance
    {
        #region Core metadata
        /// <summary>
        /// name of the instance
        /// </summary>
        public string Name;

        /// <summary>
        /// The logging provider it is an instance of
        /// </summary>
        public ProviderV2 Provider;

        /// <summary>
        /// Whether the logging provider instance is enabled. Only when this is set to true will the logging script execute its events.
        /// </summary>
        public bool Enabled;

        /// <summary>
        /// The provider instance has had its initial runtime configuration (what is stored in the BeginEvent) applied.
        /// </summary>
        public bool Initialized;
        #endregion Core metadata

        #region Constructor & Utils
        /// <summary>
        /// Creates a new instance of a logging provider
        /// </summary>
        /// <param name="Provider">The provider from which to create an instance.</param>
        /// <param name="Name">The name of the instance to create.</param>
        public ProviderInstance(ProviderV2 Provider, string Name)
        {
            this.Name = Name;
            this.Provider = Provider;

            ImportConfig();
            ProviderHost.InitializeProviderInstance(this);
        }

        private void ImportConfig()
        {
            string configRoot = $"LoggingProvider.{Provider.Name}";
            if (!String.IsNullOrEmpty(Name) && !String.Equals(Name, "Default", StringComparison.InvariantCultureIgnoreCase))
                configRoot = configRoot + $".{Name}";

            // Enabled
            Enabled = LanguagePrimitives.IsTrue(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.Enabled"));

            // Includes & Excludes
            IncludeModules = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeModules"));
            ExcludeModules = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.ExcludeModules"));
            IncludeFunctions = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeFunctions"));
            ExcludeFunctions = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.ExcludeFunctions"));
            IncludeTags = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeTags"));
            ExcludeTags = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.ExcludeTags"));
            IncludeWarning = ToBool(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeWarning"));
            MinLevel = ToInt(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.MinLevel"), 1);
            MaxLevel = ToInt(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.MaxLevel"), 9);
        }

        private List<string> ToStringList(object Entries)
        {
            if (Entries == null)
                return new List<string>();

            List<string> strings = new List<string>();
            return LanguagePrimitives.ConvertTo(Entries, strings.GetType()) as List<string>;
        }
        private bool ToBool(object Value)
        {
            if (Value == null)
                return true;
            try { return (bool)Value; }
            catch { return true; }
        }
        private int ToInt(object Value, int DefaultValue)
        {
            if (Value == null)
                return DefaultValue;
            try { return (int)Value; }
            catch { return DefaultValue; }
        }
        #endregion Constructor & Utils

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
                if (IncludeTags.Except(Entry.Tags).ToList().Count == IncludeTags.Count)
                    return false;
            }

            if (ExcludeTags.Except(Entry.Tags).ToList().Count < ExcludeTags.Count)
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

        #region Instance Module
        /// <summary>
        /// The module containing the instance content
        /// </summary>
        public PSModuleInfo Module;
        /// <summary>
        /// The function to use to execute in the begin phase
        /// </summary>
        public FunctionInfo BeginCommand;
        /// <summary>
        /// The function to use to execute the start phase
        /// </summary>
        public FunctionInfo StartCommand;
        /// <summary>
        /// The function to use to execute the message phase
        /// </summary>
        public FunctionInfo MessageCommand;
        /// <summary>
        /// The function to use to execute the error phase
        /// </summary>
        public FunctionInfo ErrorCommand;
        /// <summary>
        /// the function to use to execute the end phase
        /// </summary>
        public FunctionInfo EndCommand;
        /// <summary>
        /// The function to use to execute the final phase
        /// </summary>
        public FunctionInfo FinalCommand;
        #endregion Instance Module

        /// <summary>
        /// The last 128 errors that happenend to the provider instance
        /// </summary>
        public LimitedConcurrentQueue<ErrorRecord> Errors = new LimitedConcurrentQueue<ErrorRecord>(128);

        /// <summary>
        /// Returns the name of the provider instance.
        /// </summary>
        /// <returns>Returns the name of the provider instance.</returns>
        public override string ToString()
        {
            return Name;
        }
    }
}
