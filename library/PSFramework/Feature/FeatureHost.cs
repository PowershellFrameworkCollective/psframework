using System;
using System.Collections.Concurrent;

namespace PSFramework.Feature
{
    /// <summary>
    /// Manages the feature flag component
    /// </summary>
    public static class FeatureHost
    {
        #region Module Feature Flags
        /// <summary>
        /// Repository of features modules may opt into or out of
        /// </summary>
        private static ConcurrentDictionary<string, ConcurrentDictionary<string, bool>> _ModuleFeatureFlags = new ConcurrentDictionary<string, ConcurrentDictionary<string, bool>>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Repository of features and their global enablement state
        /// </summary>
        private static ConcurrentDictionary<string, bool> _ExperimentalFeatureFlags = new ConcurrentDictionary<string, bool>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// List of all registered features.
        /// </summary>
        public static ConcurrentDictionary<string, FeatureItem> Features = new ConcurrentDictionary<string, FeatureItem>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Sets a module-scope feature flag
        /// </summary>
        /// <param name="ModuleName">The module for which to set the feature flag</param>
        /// <param name="FeatureFlag">The flag to set it to</param>
        /// <param name="Value">The value to set it to</param>
        public static void WriteModuleFlag(string ModuleName, string FeatureFlag, bool Value)
        {
            if (!_ModuleFeatureFlags.ContainsKey(ModuleName))
                _ModuleFeatureFlags[ModuleName] = new ConcurrentDictionary<string, bool>(StringComparer.InvariantCultureIgnoreCase);
            _ModuleFeatureFlags[ModuleName][FeatureFlag] = Value;
        }

        /// <summary>
        /// Sets a global feature flag
        /// </summary>
        /// <param name="FeatureFlag">The flag to set</param>
        /// <param name="Value">The value to apply</param>
        public static void WriteGlobalFlag(string FeatureFlag, bool Value)
        {
            _ExperimentalFeatureFlags[FeatureFlag] = Value;
        }

        /// <summary>
        /// Returns whether a given feature is enabled either globally or module locally
        /// </summary>
        /// <param name="FeatureFlag">The flag to test</param>
        /// <param name="ModuleName">The module to look up (specifying this is optional, omitting this parameter will cause it to only test global flags)</param>
        /// <returns>Whether the feature is enabled</returns>
        public static bool ReadFlag(string FeatureFlag, string ModuleName = "")
        {
            if (String.IsNullOrEmpty(FeatureFlag))
                return false;
            if (_ModuleFeatureFlags.ContainsKey(ModuleName) && _ModuleFeatureFlags[ModuleName].ContainsKey(FeatureFlag))
                return _ModuleFeatureFlags[ModuleName][FeatureFlag];
            if (_ExperimentalFeatureFlags.ContainsKey(FeatureFlag) && _ExperimentalFeatureFlags[FeatureFlag])
                return true;
            return false;
        }

        /// <summary>
        /// Returns whether a module specific feature is enabled or not
        /// </summary>
        /// <param name="FeatureFlag">The feature flag to check for</param>
        /// <param name="ModuleName">The module to check in</param>
        /// <returns>Whether the features asked for is enabled for the module specified</returns>
        public static bool ReadModuleFlag(string FeatureFlag, string ModuleName)
        {
            if (String.IsNullOrEmpty(FeatureFlag))
                return false;
            if (String.IsNullOrEmpty(ModuleName))
                return false;
            if (_ModuleFeatureFlags.ContainsKey(ModuleName) && _ModuleFeatureFlags[ModuleName].ContainsKey(FeatureFlag))
                return _ModuleFeatureFlags[ModuleName][FeatureFlag];
            return false;
        }
        #endregion Module Feature Flags
    }
}
