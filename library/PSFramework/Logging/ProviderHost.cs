using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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
        public static Dictionary<string, Provider> Providers = new Dictionary<string, Provider>();

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
    }
}
