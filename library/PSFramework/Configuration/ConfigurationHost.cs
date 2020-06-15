﻿using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Concurrent;
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
        public static ConcurrentDictionary<string, Config> Configurations = new ConcurrentDictionary<string, Config>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Hashtable containing all the registered validations
        /// </summary>
        public static ConcurrentDictionary<string, ScriptBlock> Validation = new ConcurrentDictionary<string, ScriptBlock>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The list of configuration definitions, controlling how configuration data is ingested.
        /// </summary>
        public static ConcurrentDictionary<string, ScriptBlock> Schemata = new ConcurrentDictionary<string, ScriptBlock>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Deletes a configuration setting in compliance with policy.
        /// </summary>
        /// <param name="FullName">The full name of the setting the remove</param>
        /// <returns>Whether the deletion was successful</returns>
        public static bool DeleteConfiguration(string FullName)
        {
            Config configItem;
            if (!Configurations.TryGetValue(FullName, out configItem))
                throw new ItemNotFoundException(String.Format(Localization.LocalizationHost.ReadLog("PSFramework.Assembly.ConfigurationHost.ConfigNotFound"), FullName));
            if (!configItem.AllowDelete || configItem.PolicyEnforced)
                return false;

            Configurations.TryRemove(FullName, out configItem);
            return true;
        }

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
                case "System.Collections.Hashtable":
                    List<string> hashItems = new List<string>();
                    Hashtable tempTable = Item as Hashtable;
                    foreach (object key in tempTable.Keys)
                        hashItems.Add(String.Format("{0}þEþ{1}", Utf8ToBase64(key.ToString()), Utf8ToBase64(ConvertToPersistedValue(tempTable[key]).TypeQualifiedPersistedValue)));
                    return new ConfigurationValue(String.Join("þHþ", hashItems), ConfigurationValueType.Hashtable);
                case "System.Object[]":
                    List<string> items = new List<string>();

                    foreach (object item in (object[])Item)
                    {
                        ConfigurationValue temp = ConvertToPersistedValue(item);
                        if (temp.PersistedValue == "<type not supported>")
                            return temp;
                        items.Add(String.Format("{0}:{1}", temp.PersistedType, temp.PersistedValue));
                    }

                    return new ConfigurationValue(String.Join("þþþ", items), ConfigurationValueType.Array);
                default:
                    return new ConfigurationValue(Utility.UtilityHost.CompressString((PSSerializer.Serialize(Item))), ConfigurationValueType.Object);
            }
        }

        /// <summary>
        /// Converts a persisted value back to its original data type
        /// </summary>
        /// <param name="PersistedValue">The value in its persisted state</param>
        /// <param name="Type">The type of the persisted value</param>
        /// <returns>The natural state of the value originally persisted</returns>
        public static object ConvertFromPersistedValue(string PersistedValue, ConfigurationValueType Type)
        {
            switch (Type)
            {
                case ConfigurationValueType.Null:
                    return null;
                case ConfigurationValueType.Bool:
                    return PersistedValue == "true";
                case ConfigurationValueType.Int:
                    return Int32.Parse(PersistedValue);
                case ConfigurationValueType.Long:
                    return Int64.Parse(PersistedValue);
                case ConfigurationValueType.Double:
                    return Double.Parse(PersistedValue, System.Globalization.CultureInfo.InvariantCulture);
                case ConfigurationValueType.String:
                    return PersistedValue;
                case ConfigurationValueType.Timespan:
                    return new TimeSpan(long.Parse(PersistedValue));
                case ConfigurationValueType.Datetime:
                    return new DateTime(long.Parse(PersistedValue));
                case ConfigurationValueType.ConsoleColor:
                    return Enum.Parse(typeof(ConsoleColor), PersistedValue);
                case ConfigurationValueType.Hashtable:
                    string[] hashItems = PersistedValue.Split(new string[1] { "þHþ" }, StringSplitOptions.None);
                    Hashtable tempTable = new Hashtable();
                    foreach (string tempValue in hashItems)
                    {
                        string[] tempPair = tempValue.Split(new string[1] { "þEþ" }, StringSplitOptions.None);
                        tempTable[Base64ToUtf8(tempPair[0])] = ConvertFromPersistedValue(Base64ToUtf8(tempPair[1]));
                    }
                    return tempTable;
                case ConfigurationValueType.Array:
                    string[] items = PersistedValue.Split(new string[1] { "þþþ" }, StringSplitOptions.None);
                    List<object> results = new List<object>();
                    foreach (string item in items)
                    {
                        int index = item.IndexOf(':');
                        if (index > 0)
                            results.Add(ConvertFromPersistedValue(item.Substring(index + 1), (ConfigurationValueType)Enum.Parse(typeof(ConfigurationValueType), item.Substring(0, index), true)));
                    }
                    return results.ToArray();
                case ConfigurationValueType.Object:
                    return PSSerializer.Deserialize(Utility.UtilityHost.ExpandString(PersistedValue));
                default:
                    return "<type not supported>";
            }
        }

        /// <summary>
        /// Converts a persisted value back to its original data type
        /// </summary>
        /// <param name="TypeQualifiedPersistedValue">The value in its persisted state, with a prefixed type identifier.</param>
        /// <returns>The natural state of the value originally persisted</returns>
        public static object ConvertFromPersistedValue(string TypeQualifiedPersistedValue)
        {
            int index = TypeQualifiedPersistedValue.IndexOf(':');
            if (index < 1)
                throw new ArgumentException(String.Format("Bad persisted configuration value! Could not find type qualifier on {0}", TypeQualifiedPersistedValue));
            ConfigurationValueType type = (ConfigurationValueType)Enum.Parse(typeof(ConfigurationValueType), TypeQualifiedPersistedValue.Substring(0, index), true);
            string valueString = TypeQualifiedPersistedValue.Substring(index + 1);
            return ConvertFromPersistedValue(valueString, type);
        }

        /// <summary>
        /// Retrieve the configuration value only.
        /// Returns null if the configuration entry does not exist.
        /// </summary>
        /// <param name="FullName">The full name of the configuration object of which to return the value</param>
        /// <returns>The value of the configuration entry.</returns>
        public static object GetConfigValue(string FullName)
        {
            Config configItem;
            if (!Configurations.TryGetValue(FullName, out configItem))
                return null;
            return configItem.Value;
        }

        #region Private methods
        /// <summary>
        /// Converts a plain text into a base64 string
        /// </summary>
        /// <param name="Value">The string to convert</param>
        /// <returns>base64 encoded version of string.</returns>
        private static string Utf8ToBase64(string Value)
        {
            return Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(Value));
        }

        /// <summary>
        /// Converts a base64 encoded string into plain text
        /// </summary>
        /// <param name="Value">The string to convert</param>
        /// <returns>Plain Text string</returns>
        private static string Base64ToUtf8(string Value)
        {
            return System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(Value));
        }
        #endregion Private methods
    }
}
