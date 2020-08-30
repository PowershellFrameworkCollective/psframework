using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;

namespace PSFramework.Logging
{
    /// <summary>
    /// Provides infrastructure services for the logging provider system
    /// </summary>
    public static class ProviderHost
    {
        /// <summary>
        /// Dictionary with all registered logging providers
        /// </summary>
        public static ConcurrentDictionary<string, Provider> Providers = new ConcurrentDictionary<string, Provider>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The current state of the logging system
        /// </summary>
        public static LoggingState LoggingState = LoggingState.Unstarted;

        /// <summary>
        /// Returns all enabled logging providers
        /// </summary>
        /// <returns>All enabled logging providers</returns>
        public static List<Provider> GetEnabled()
        {
            List<Provider> list = new List<Provider>();
            foreach (Provider prov in Providers.Values)
                if (prov.Enabled && (prov as ProviderV2) == null)
                    list.Add(prov);
            return list;
        }

        /// <summary>
        /// Returns all enabled &amp; initialized logging provider
        /// </summary>
        /// /// <param name="IncludeDisabled">Whether disabled providers should also be returned</param>
        /// <returns></returns>
        public static List<Provider> GetInitialized(bool IncludeDisabled = false)
        {
            List<Provider> list = new List<Provider>();
            foreach (Provider prov in Providers.Values)
                if ((prov.Enabled || IncludeDisabled) && prov.Initialized && (prov as ProviderV2) == null)
                    list.Add(prov);
            return list;
        }

        /// <summary>
        /// Returns all enabled provider instances
        /// </summary>
        /// <returns>All enabled provider instances</returns>
        public static List<ProviderInstance> GetEnabledInstances()
        {
            List<ProviderInstance> results = new List<ProviderInstance>();

            foreach (Provider prov in Providers.Values)
            {
                if ((prov as ProviderV2) == null)
                    continue;

                ProviderV2 prov2 = (ProviderV2)prov;
                foreach (ProviderInstance inst in prov2.Instances.Values.Where(o => o.Enabled))
                    results.Add(inst);
            }

            return results;
        }

        /// <summary>
        /// Returns all enabled and initialized provider instances
        /// </summary>
        /// <param name="IncludeDisabled">Whether disabled instances should also be returned</param>
        /// <returns>All enabled and initialized provider instances</returns>
        public static List<ProviderInstance> GetInitializedInstances(bool IncludeDisabled = false)
        {
            List<ProviderInstance> results = new List<ProviderInstance>();

            foreach (Provider prov in Providers.Values)
            {
                if ((prov as ProviderV2) == null)
                    continue;

                ProviderV2 prov2 = (ProviderV2)prov;
                foreach (ProviderInstance inst in prov2.Instances.Values.Where(o => (o.Enabled || IncludeDisabled) && o.Initialized))
                    results.Add(inst);
            }

            return results;
        }

        /// <summary>
        /// The scriptblock used to create the dynamic module implementing the logging provider generation 2 logging instance.
        /// </summary>
        public static ScriptBlock ProviderV2ModuleScript;

        /// <summary>
        /// Initializes a logging provider instance, creating the dynamic module needed and updating its metadata to reflect this change.
        /// </summary>
        /// <param name="Instance">The instance to initialize</param>
        internal static void InitializeProviderInstance(ProviderInstance Instance)
        {
            Utility.UtilityHost.ImportScriptBlock(ProviderV2ModuleScript);
            ProviderV2ModuleScript.Invoke(Instance);
        }

        /// <summary>
        /// Updates all V2 provider instances, creating new ones depending on configuration.
        /// </summary>
        public static void UpdateAllInstances()
        {
            foreach (Provider prov in Providers.Values.Where(o => (o as ProviderV2) != null))
                ((ProviderV2)prov).UpdateInstances();
        }
    }
}
