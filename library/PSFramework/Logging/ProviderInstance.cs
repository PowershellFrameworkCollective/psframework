using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Management.Automation;
using PSFramework.Utility;
using PSFramework.Message;

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
        }

        /// <summary>
        /// Refreshes the filter and enablement settings from configuration
        /// </summary>
        public void ImportConfig()
        {
            string configRoot = $"LoggingProvider.{Provider.Name}";
            if (!String.IsNullOrEmpty(Name) && !String.Equals(Name, "Default", StringComparison.InvariantCultureIgnoreCase))
                configRoot = configRoot + $".{Name}";

            // Includes & Excludes
            IncludeModules = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeModules"));
            ExcludeModules = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.ExcludeModules"));
            IncludeFunctions = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeFunctions"));
            ExcludeFunctions = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.ExcludeFunctions"));
            IncludeRunspaces = ToGuidList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeRunspaces"));
            ExcludeRunspaces = ToGuidList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.ExcludeRunspaces"));
            IncludeTags = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeTags"));
            ExcludeTags = ToStringList(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.ExcludeTags"));
            IncludeWarning = ToBool(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeWarning"));
            IncludeError = ToBool(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.IncludeError"));
            MinLevel = ToInt(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.MinLevel"), 1);
            MaxLevel = ToInt(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.MaxLevel"), 9);
            RequiresInclude = ToBool(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.RequiresInclude"), false);

            if (null == Module)
            {
                ProviderHost.InitializeProviderInstance(this);
                if (Errors.Count == 0)
                    Enabled = LanguagePrimitives.IsTrue(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.Enabled"));
            }
            else
                Enabled = LanguagePrimitives.IsTrue(Configuration.ConfigurationHost.GetConfigValue($"{configRoot}.Enabled"));
        }

        private List<string> ToStringList(object Entries)
        {
            if (Entries == null)
                return new List<string>();

            List<string> strings = new List<string>();
            return LanguagePrimitives.ConvertTo(Entries, strings.GetType()) as List<string>;
        }
        private bool ToBool(object Value, bool Default = true)
        {
            if (Value == null)
                return Default;
            try { return (bool)Value; }
            catch { return Default; }
        }
        private int ToInt(object Value, int DefaultValue)
        {
            if (Value == null)
                return DefaultValue;
            try { return (int)Value; }
            catch { return DefaultValue; }
        }
        private List<Guid> ToGuidList(object Entries)
        {
            List<Guid> tempList = new List<Guid>();

            if (Entries == null)
                return tempList;
            object[] data = LanguagePrimitives.ConvertTo<object[]>(Entries);
            foreach (object datum in data)
            {
                try { tempList.Add(LanguagePrimitives.ConvertTo<Guid>(datum)); }
                catch { } // don't care about bad input
            }

            return tempList;
        }
        #endregion Constructor & Utils

        #region Message filtering
        /// <summary>
        /// Whether any include rule must apply before the instance accepts a message.
        /// </summary>
        public bool RequiresInclude = false;

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
        /// List of runspaces to include. Only messages from one of these runspaces will be considered by this provider instance.
        /// </summary>
        public List<Guid> IncludeRunspaces
        {
            get
            {
                return _IncludeRunspaces;
            }
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
        /// List of runspaces to exclude. Messages from these runspaces will be ignored by this provider instance.
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
        /// Whether to include error messages in the log
        /// </summary>
        public bool IncludeError = true;

        /// <summary>
        /// Deadline after which no more messages can be accepted. Used during the logging provider disablement workflow and should not be used outside that.
        /// </summary>
        public DateTime? NotAfter;

        /// <summary>
        /// Tests whether a log entry applies to the provider instance
        /// </summary>
        /// <param name="Entry">The Entry to validate</param>
        /// <returns>Whether it applies</returns>
        public bool MessageApplies(Message.LogEntry Entry)
        {
            bool wasIncluded = false;

            // Expired
            if (NotAfter != null && NotAfter < Entry.Timestamp)
                return false;

            // Level
            if (!IncludeWarning && (Entry.Level == Message.MessageLevel.Warning))
                return false;
            if (!IncludeError && (Entry.Level == Message.MessageLevel.Error))
                return false;
            if (((_MinLevel != 1) || (_MaxLevel != 9)) && (Entry.Level != Message.MessageLevel.Warning) && (Entry.Level != Message.MessageLevel.Error))
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
                wasIncluded = true;
            }

            foreach (string module in ExcludeModules)
                if (string.Equals(Entry.ModuleName, module, StringComparison.InvariantCultureIgnoreCase))
                    return false;

            // Runspaces
            if (IncludeRunspaces.Count > 0 && !IncludeRunspaces.Contains(Entry.Runspace))
                return false;
            else if (IncludeRunspaces.Count > 0)
                wasIncluded = true;
            if (ExcludeRunspaces.Contains(Entry.Runspace))
                return false;
            if (_DynamicRunspaceInclusion.ContainsKey(Entry.Runspace) && _DynamicRunspaceInclusion[Entry.Runspace].TimeRanges.Count > 0)
            {
                if (_DynamicRunspaceInclusion[Entry.Runspace].IsInRange(Entry.Timestamp))
                    wasIncluded = true;
                _DynamicRunspaceInclusion[Entry.Runspace].RemoveBefore(Entry.Timestamp);
            }

            // Functions
            if (IncludeFunctions.Count > 0)
            {
                bool test = false;
                foreach (string function in IncludeFunctions)
                    if (UtilityHost.IsLike(Entry.FunctionName, function))
                        test = true;

                if (!test)
                    return false;
                wasIncluded = true;
            }

            foreach (string function in ExcludeFunctions)
                if (UtilityHost.IsLike(Entry.FunctionName, function))
                    return false;

            // Tags
            if (IncludeTags.Count > 0)
            {
                if (IncludeTags.Except(Entry.Tags, StringComparer.InvariantCultureIgnoreCase).ToList().Count == IncludeTags.Count)
                    return false;
                wasIncluded = true;
            }

            if (ExcludeTags.Except(Entry.Tags, StringComparer.InvariantCultureIgnoreCase).ToList().Count < ExcludeTags.Count)
                return false;

            if (RequiresInclude && !wasIncluded)
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
            bool wasIncluded = false;

            // Expired
            if (NotAfter != null && NotAfter < Record.Timestamp)
                return false;

            // Modules
            if (IncludeModules.Count > 0)
            {
                bool test = false;
                foreach (string module in IncludeModules)
                    if (string.Equals(Record.ModuleName, module, StringComparison.InvariantCultureIgnoreCase))
                        test = true;

                if (!test)
                    return false;
                wasIncluded = true;
            }

            foreach (string module in ExcludeModules)
                if (string.Equals(Record.ModuleName, module, StringComparison.InvariantCultureIgnoreCase))
                    return false;

            // Runspaces
            if (IncludeRunspaces.Count > 0 && !IncludeRunspaces.Contains(Record.Runspace))
                return false;
            else if (IncludeRunspaces.Count > 0)
                wasIncluded = true;
            if (ExcludeRunspaces.Contains(Record.Runspace))
                return false;
            if (_DynamicRunspaceInclusion.ContainsKey(Record.Runspace) && _DynamicRunspaceInclusion[Record.Runspace].TimeRanges.Count > 0)
            {
                if (_DynamicRunspaceInclusion[Record.Runspace].IsInRange(Record.Timestamp))
                    wasIncluded = true;
            }

            // Functions
            if (IncludeFunctions.Count > 0)
            {
                bool test = false;
                foreach (string function in IncludeFunctions)
                    if (UtilityHost.IsLike(Record.FunctionName, function))
                        test = true;

                if (!test)
                    return false;
                wasIncluded = true;
            }

            foreach (string function in ExcludeFunctions)
                if (UtilityHost.IsLike(Record.FunctionName, function))
                    return false;

            // Tags
            if (IncludeTags.Count > 0)
            {
                if (IncludeTags.Except(Record.Tags).ToList().Count == IncludeTags.Count)
                    return false;
                wasIncluded = true;
            }

            if (ExcludeTags.Except(Record.Tags).ToList().Count < ExcludeTags.Count)
                return false;

            if (RequiresInclude && !wasIncluded)
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

        private ConcurrentDictionary<Guid, TimeRangeContainer> _DynamicRunspaceInclusion = new ConcurrentDictionary<Guid, TimeRangeContainer>();
        /// <summary>
        /// Add a runspace ID to the list of included runspaces. This is threadsafe.
        /// </summary>
        /// <param name="Runspace">ID of the runspace to add.</param>
        public void AddRunspace(Guid Runspace)
        {
            _DynamicRunspaceInclusion.TryAdd(Runspace, new TimeRangeContainer());
            _DynamicRunspaceInclusion[Runspace].Start(DateTime.Now);
        }
        /// <summary>
        /// Remove a runspace ID from the list of included runspaces. This is threadsafe.
        /// </summary>
        /// <param name="Runspace">The runspace to remove.</param>
        public void RemoveRunspace(Guid Runspace)
        {
            if (_DynamicRunspaceInclusion.ContainsKey(Runspace))
                _DynamicRunspaceInclusion[Runspace].End(DateTime.Now);
        }

        /// <summary>
        /// Wait until all applicable messages have been processed, then disable this instance.
        /// </summary>
        /// <param name="WaitForFinalize">Wait until the the final block of the instance has been executed.</param>
        /// <exception cref="TimeoutException">Will not wait longer than five minutes to drain messages.</exception>
        public void Drain(bool WaitForFinalize = true)
        {
            if (null == NotAfter)
                NotAfter = DateTime.Now;

            DateTime limit = DateTime.Now.AddMinutes(5);

            // Wait until all messages are done processing
            LogEntry entry;
            while (LogHost.OutQueueLog.Count > 0)
            {
                LogHost.OutQueueLog.TryPeek(out entry);
                if (entry == null || entry.Timestamp > NotAfter)
                    break;

                System.Threading.Thread.Sleep(250);

                if (limit > DateTime.Now)
                    throw new TimeoutException();
            }

            // Wait until all errors are done processing
            PsfExceptionRecord error;
            while (LogHost.OutQueueError.Count > 0)
            {
                LogHost.OutQueueError.TryPeek(out error);
                if (error == null || error.Timestamp > NotAfter)
                    break;

                System.Threading.Thread.Sleep(250);

                if (limit < DateTime.Now)
                    throw new TimeoutException();
            }

            // Disable Provider Instance
            string configRoot = $"LoggingProvider.{Provider.Name}";
            if (!String.IsNullOrEmpty(Name) && !String.Equals(Name, "Default", StringComparison.InvariantCultureIgnoreCase))
                configRoot = configRoot + $".{Name}";

            Configuration.ConfigurationHost.Configurations[$"{configRoot}.Enabled"].Value = false;
            Enabled = false;

            // Reset NotAfter in case the instance is later reenabled
            NotAfter = null;

            if (!WaitForFinalize)
                return;

            while (Initialized)
            {
                System.Threading.Thread.Sleep(250);

                if (limit < DateTime.Now)
                {
                    if (Errors.Count == 0)
                        throw new TimeoutException("Logging was concluded, but timeout was reached while waiting for the final sequence of the logging provider to complete.");
                    else
                    {
                        ErrorRecord lastError = Errors.Last();
                        throw new TimeoutException($"Logging was concluded, but timeout was reached while waiting for the final sequence of the logging provider to complete. Last Error: {lastError.ToString()}", lastError.Exception);
                    }
                }
            }
        }

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
