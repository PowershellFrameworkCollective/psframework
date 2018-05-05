using System;
using System.Collections.Generic;
using System.Management.Automation;

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
        /// Hashtable containing all the registered validations
        /// </summary>
        public static Dictionary<string, ScriptBlock> Validation = new Dictionary<string, ScriptBlock>();

        /// <summary>
        /// Whether the import from registry has been completed. Prevents multiple imports and overwrites when importing the module multiple times.
        /// </summary>
        public static bool ImportFromRegistryDone;

        /// <summary>
        /// Converts any object into its persisted state.
        /// </summary>
        /// <param name="Item">The item to convert.</param>
        /// <returns>Its persisted state representation.</returns>
        public static ConfigurationValue ConvertToPersistedValue(object Item)
        {
            if (Item == null)
                return new ConfigurationValue("null", ConfigurationValueType.Null);

            switch (Item.GetType().FullName)
            {
                case "System.Boolean":
                    if ((bool)Item)
                        return new ConfigurationValue("true", ConfigurationValueType.Bool);
                    return new ConfigurationValue("false", ConfigurationValueType.Bool);
                case "System.Int16":
                    return new ConfigurationValue(Item.ToString(), ConfigurationValueType.Int);
                case "System.Int32":
                    return new ConfigurationValue(Item.ToString(), ConfigurationValueType.Int);
                case "System.Int64":
                    return new ConfigurationValue(Item.ToString(), ConfigurationValueType.Long);
                case "System.UInt16":
                    return new ConfigurationValue(Item.ToString(), ConfigurationValueType.Int);
                case "System.UInt32":
                    return new ConfigurationValue(Item.ToString(), ConfigurationValueType.Long);
                case "System.UInt64":
                    return new ConfigurationValue(Item.ToString(), ConfigurationValueType.Long);
                case "System.Double":
                    return new ConfigurationValue(String.Format(System.Globalization.CultureInfo.InvariantCulture, "{0}", Item), ConfigurationValueType.Double);
                case "System.String":
                    return new ConfigurationValue(Item.ToString(), ConfigurationValueType.String);
                case "System.TimeSpan":
                    return new ConfigurationValue(((TimeSpan)Item).Ticks.ToString(), ConfigurationValueType.Timespan);
                case "System.DateTime":
                    return new ConfigurationValue(((DateTime)Item).Ticks.ToString(), ConfigurationValueType.Datetime);
                case "System.ConsoleColor":
                    return new ConfigurationValue(Item.ToString(), ConfigurationValueType.ConsoleColor);
                case "System.Object[]":
                    List<string> items = new List<string>();

                    foreach (object item in (object[])Item)
                    {
                        string temp = ConvertToPersistedValue(item);
                        if (temp == "<type not supported>")
                            return temp;
                        items.Add(temp);
                    }

                    return String.Format("array:{0}", String.Join("þþþ", items));
                default:
                    return String.Format("object:{0}", Utility.UtilityHost.CompressString((PSSerializer.Serialize(Item))));
            }
        }

        public static object ConvertFromPersistedValue(string PersistedValue, ConfigurationValueType Type)
        {
            return null;
        }
    }
}
