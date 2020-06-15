using System;
using System.Collections.Concurrent;
using System.Collections.Generic;

namespace PSFramework.Localization
{
    /// <summary>
    /// Helper class that offers static resources for the localization component
    /// </summary>
    public static class LocalizationHost
    {
        /// <summary>
        /// The language to display text with by default. Will use thread information if not set.
        /// </summary>
        public static string Language = "";

        /// <summary>
        /// The default language to log in.
        /// </summary>
        public static string LoggingLanguage = "en-US";

        /// <summary>
        /// List of strings registered
        /// </summary>
        public static ConcurrentDictionary<string, LocalString> Strings = new ConcurrentDictionary<string, LocalString>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Mapping module name to the language to use for logging.
        /// </summary>
        public static ConcurrentDictionary<string, string> ModuleLoggingLanguage = new ConcurrentDictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Configure the module specific logging language.
        /// </summary>
        /// <param name="Module">The module to configure</param>
        /// <param name="Language">The language to set. Leave empty to remove entry.</param>
        public static void SetLoggingLanguage(string Module, string Language)
        {
            ModuleLoggingLanguage[Module] = Language;
            string dummy;
            if (String.IsNullOrEmpty(Language))
                ModuleLoggingLanguage.TryRemove(Module, out dummy);
        }

        /// <summary>
        /// Writes a localized string. If needed creates it, then sets the text of the specified language.
        /// </summary>
        /// <param name="FullName">The name of the value to set</param>
        /// <param name="Language">The language to set it for</param>
        /// <param name="Text">The text to register</param>
        public static void Write(string FullName, string Language, string Text)
        {
            LocalString localString;
            if (!Strings.TryGetValue(FullName, out localString))
            {
                localString = Strings.GetOrAdd(FullName, new LocalString(FullName));
            }
            localString.Set(Language, Text);
        }

        /// <summary>
        /// Writes a localized string. If needed creates it, then sets the text of the specified language.
        /// </summary>
        /// <param name="Module">The name of the module for which to set a value</param>
        /// <param name="Name">The name of the text for which to set the value</param>
        /// <param name="Language">The language to set it for</param>
        /// <param name="Text">The text to register</param>
        public static void Write(string Module, string Name, string Language, string Text)
        {
            string tempFullName = string.Join(".", Module, Name);
            LocalString localString;
            if (!Strings.TryGetValue(tempFullName, out localString))
            {
                localString = Strings.GetOrAdd(tempFullName, new LocalString(Module, Name));
            }
            localString.Set(Language, Text);
        }

        /// <summary>
        /// Reads a localized string from the list of available strings
        /// </summary>
        /// <param name="FullName">The name of the string to request. Include the modulename</param>
        /// <returns>The localized string requested. Empty string if nothing.</returns>
        public static string Read(string FullName)
        {
            LocalString localString;
            if (!Strings.TryGetValue(FullName, out localString))
            {
                return string.Empty;
            }
            return localString.Value;
        }

        /// <summary>
        /// Reads a localized string from the list of available strings
        /// </summary>
        /// <param name="FullName">The name of the string to request. Include the modulename</param>
        /// <param name="StringValues">The values to format into the string</param>
        /// <returns>The localized string requested. Empty string if nothing.</returns>
        public static string Read(string FullName, object[] StringValues)
        {
            LocalString localString;
            if (!Strings.TryGetValue(FullName, out localString))
            {
                return string.Format("<String Key not found: {0}>", FullName);
            }
            return string.Format(localString.Value, StringValues);
        }

        /// <summary>
        /// Reads a localized string from the list of available strings
        /// </summary>
        /// <param name="ModuleName">The name of the module the string belongs to.</param>
        /// <param name="Name">The individual name of the setting.</param>
        /// <param name="StringValues">The values to format into the string</param>
        /// <returns>The localized string requested. Empty string if nothing.</returns>
        public static string Read(string ModuleName, string Name, object[] StringValues)
        {
            string fullname = Name;
            if (!String.IsNullOrEmpty(ModuleName) && (ModuleName != "<Unknown>"))
                fullname = String.Format("{0}.{1}", ModuleName, Name);
            LocalString localString;
            if (!Strings.TryGetValue(fullname, out localString))
            {
                return string.Format("<String Key not found: {0}>", fullname);
            }
            return string.Format(localString.Value, StringValues);
        }

        /// <summary>
        /// Reads a localized string from the list of available strings for the purpose of logging
        /// </summary>
        /// <param name="FullName">The name of the string to request. Include the modulename</param>
        /// <returns>The localized string requested. Empty string if nothing.</returns>
        public static string ReadLog(string FullName)
        {
            LocalString localString;
            if (!Strings.TryGetValue(FullName, out localString))
            {
                return string.Format("<String Key not found: {0}>", FullName);
            }
            return localString.LogValue;
        }

        /// <summary>
        /// Reads a localized string from the list of available strings for the purpose of logging
        /// </summary>
        /// <param name="FullName">The name of the string to request. Include the modulename</param>
        /// <param name="StringValues">The values to format into the string</param>
        /// <returns>The localized string requested. Empty string if nothing.</returns>
        public static string ReadLog(string FullName, object[] StringValues)
        {
            LocalString localString;
            if (!Strings.TryGetValue(FullName, out localString))
            {
                return string.Format("<String Key not found: {0}>", FullName);
            }
            return string.Format(localString.LogValue, StringValues);
        }

        /// <summary>
        /// Reads a localized string from the list of available strings for the purpose of logging
        /// </summary>
        /// <param name="ModuleName">The name of the module the string belongs to.</param>
        /// <param name="Name">The individual name of the setting.</param>
        /// <param name="StringValues">The values to format into the string</param>
        /// <returns>The localized string requested. Empty string if nothing.</returns>
        public static string ReadLog(string ModuleName, string Name, object[] StringValues)
        {
            string fullname = Name;
            if (!String.IsNullOrEmpty(ModuleName) && (ModuleName != "<Unknown>"))
                fullname = String.Format("{0}.{1}", ModuleName, Name);
            LocalString localString;
            if (!Strings.TryGetValue(fullname, out localString))
            {
                return string.Format("<String Key not found: {0}>", fullname);
            }
            return string.Format(localString.LogValue, StringValues);
        }
    }
}
