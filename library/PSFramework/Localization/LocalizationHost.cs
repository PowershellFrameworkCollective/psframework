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
        /// List of strings registered
        /// </summary>
        public static Dictionary<string, LocalString> Strings = new Dictionary<string, LocalString>();

        /// <summary>
        /// Writes a localized string. If needed creates it, then sets the text of the specified language.
        /// </summary>
        /// <param name="FullName">The name of the value to set</param>
        /// <param name="Language">The language to set it for</param>
        /// <param name="Text">The text to register</param>
        public static void Write(string FullName, string Language, string Text)
        {
            if (!Strings.ContainsKey(FullName))
                Strings[FullName] = new LocalString(FullName);
            Strings[FullName].Set(Language, Text);
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
            if (!Strings.ContainsKey(tempFullName))
                Strings[tempFullName] = new LocalString(Module, Name);
            Strings[tempFullName].Set(Language, Text);
        }

        /// <summary>
        /// Reads a localized string from the list of available strings
        /// </summary>
        /// <param name="FullName">The name of the string to request. Include the modulename</param>
        /// <returns>The localized string requested. Empty string if nothing.</returns>
        public static string Read(string FullName)
        {
            if (!Strings.ContainsKey(FullName))
                return "";
            return Strings[FullName].Value;
        }
    }
}
