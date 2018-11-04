using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace PSFramework.Localization
{
    /// <summary>
    /// A string used for localized text
    /// </summary>
    public class LocalString
    {
        private Dictionary<string, string> _Strings = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The name of the module the string is a part of
        /// </summary>
        public string Module;

        /// <summary>
        /// The name of the string
        /// </summary>
        public string Name;

        /// <summary>
        /// The full, public name of the string
        /// </summary>
        public string FullName
        {
            get { return String.Format("{0}.{1}", Module, Name); }
        }

        /// <summary>
        /// The actual string value of the text
        /// </summary>
        public string Value
        {
            get
            {
                if (_Strings.Keys.Count == 0)
                    throw new InvalidOperationException("Cannot offer string value without at least ONE string registered");

                if (_Strings.ContainsKey(LocalizationHost.Language))
                    return _Strings[LocalizationHost.Language];
                if (_Strings.ContainsKey(CultureInfo.CurrentUICulture.Name))
                    return _Strings[CultureInfo.CurrentUICulture.Name];

                return _Strings.Values.First();
            }
        }

        /// <summary>
        /// Sets the text for a specific language
        /// </summary>
        /// <param name="Language">The language to set it for (eg: en-US; not case sensitive)</param>
        /// <param name="Text">The text to apply</param>
        public void Set(string Language, string Text)
        {
            _Strings[Language] = Text;
        }
        
        /// <summary>
        /// Returns a list of all strings
        /// </summary>
        /// <returns>The strings in all languages available</returns>
        public Dictionary<string, string> GetAll()
        {
            return new Dictionary<string, string>(_Strings);
        }

        /// <summary>
        /// Creates a new localized string
        /// </summary>
        /// <param name="Module"></param>
        /// <param name="Name"></param>
        public LocalString(string Module, string Name)
        {
            this.Module = Module;
            this.Name = Name;
        }

        /// <summary>
        /// Creates a new localized string
        /// </summary>
        /// <param name="FullName"></param>
        public LocalString(string FullName)
        {
            Module = FullName.Split('.')[0];
            Name = FullName.Split('.')[1];
        }
    }
}
