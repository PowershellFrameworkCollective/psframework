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
            IncludeTags = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeTags"));
            ExcludeTags = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.ExcludeTags"));
        }

        private List<string> ToStringList(object Entries)
        {
            if (Entries == null)
                return new List<string>();

            List<string> strings = new List<string>();
            return LanguagePrimitives.ConvertTo(Entries, strings.GetType()) as List<string>;
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

        /// <summary>
        /// Tests whether a log entry applies to the provider instance
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

            foreach (string module in ExcludeModules)
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
        /// Tests whether an error record applies to the provider instance
        /// </summary>
        /// <param name="Record">The error record to test</param>
        /// <returns>Whether it applies to the provider instance</returns>
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
