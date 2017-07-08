using System;
using System.Collections.Generic;

namespace PSFramework.Configuration
{
    /// <summary>
    /// Host class providing static configuration settings that are constant across all runspaces within the process.
    /// </summary>
    public static class ConfigurationHost
    {
        /// <summary>
        /// Hashtable containing all the configuration entries
        /// </summary>
        public static Dictionary<string, Config> Configurations = new Dictionary<string, Config>();

        /// <summary>
        /// Whether the import from registry has been completed. Prevents multiple imports and overwrites when importing the module multiple times.
        /// </summary>
        public static bool ImportFromRegistryDone;
    }
}
