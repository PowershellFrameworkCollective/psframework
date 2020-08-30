using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;
using PSFramework.Utility;

namespace PSFramework.Logging
{
    /// <summary>
    /// A generation 2 logging provider, supporting resource isolation and multi-instance operation
    /// </summary>
    public class ProviderV2 : Provider
    {
        /// <summary>
        /// The generation of the logging provider.
        /// </summary>
        public new ProviderVersion ProviderVersion = ProviderVersion.Version_2;

        /// <summary>
        /// The list of instances currently enabled
        /// </summary>
        public Dictionary<string, ProviderInstance> Instances = new Dictionary<string, ProviderInstance>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The root configuration name.
        /// Used by instances to facilitate instance-specific configuration retrieval.
        /// </summary>
        public string ConfigurationRoot;

        /// <summary>
        /// List of configuration properties one can assign to a logging provider instance.
        /// Maps directly to instance-specific configuration keys.
        /// Mostly for documentation purposes.
        /// </summary>
        public string[] InstanceProperties;

        /// <summary>
        /// Functions used by the logging provider instances.
        /// </summary>
        public PsfScriptBlock Functions;

        /// <summary>
        /// List of enabled instances
        /// </summary>
        public ProviderInstance[] EnabledInstances
        {
            get
            {
                List<ProviderInstance> result = new List<ProviderInstance>();

                foreach (ProviderInstance instance in Instances.Values.Where(o => o.Enabled))
                    result.Add(instance);

                return result.ToArray();
            }
        }

        /// <summary>
        /// List of disabled instances
        /// </summary>
        public ProviderInstance[] DisabledInstances
        {
            get
            {
                List<ProviderInstance> result = new List<ProviderInstance>();

                foreach (ProviderInstance instance in Instances.Values.Where(o => o.Enabled == false))
                    result.Add(instance);

                return result.ToArray();
            }
        }

        /// <summary>
        /// The default values to include in configuration for new instances
        /// </summary>
        public Hashtable ConfigurationDefaultValues;

        /// <summary>
        /// Creates provider instances based on configuration.
        /// </summary>
        public void UpdateInstances()
        {
            if (!Instances.ContainsKey("Default"))
                Instances["Default"] = new ProviderInstance(this, "Default");

            string configPattern = $"LoggingProvider\\.{Name}\\.(.+)\\.Enabled";
            Regex regex = new Regex(configPattern, RegexOptions.IgnoreCase);

            foreach (string name in Configuration.ConfigurationHost.Configurations.Keys)
            {
                if (!regex.IsMatch(name))
                    continue;

                Match match = regex.Match(name);
                if (!Instances.ContainsKey(match.Groups[1].Value))
                    Instances[match.Groups[1].Value] = new ProviderInstance(this, match.Groups[1].Value);
            }

            bool enableState = false;
            if (Instances.Values.Where(o => o.Enabled).Count() > 0)
                enableState = true;
            Enabled = enableState;
        }
    }
}
