using System.Collections.Concurrent;
using System.Collections.Generic;

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
        public static ConcurrentDictionary<string, Provider> Providers = new ConcurrentDictionary<string, Provider>();

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
                if (prov.Enabled)
                    list.Add(prov);
            return list;
        }

        /// <summary>
        /// Returns all enabled &amp; initialized logging provider
        /// </summary>
        /// <returns></returns>
        public static List<Provider> GetInitialized()
        {
            List<Provider> list = new List<Provider>();
            foreach (Provider prov in Providers.Values)
                if (prov.Enabled && prov.Initialized)
                    list.Add(prov);
            return list;
        }
    }
}
