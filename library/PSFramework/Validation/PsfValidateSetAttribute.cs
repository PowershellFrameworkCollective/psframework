using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;

namespace PSFramework.Validation
{
    /// <summary>
    /// Class for validating against a set of legal values. Set can be dynamically calculated.
    /// </summary>
    public class PsfValidateSetAttribute : ValidateEnumeratedArgumentsAttribute
    {
        #region Public attribute properties
        /// <summary>
        /// Gets the scriptblock to be used in the validation
        /// </summary>
        public ScriptBlock ScriptBlock;

        /// <summary>
        /// Gets a list of string values to be used in the validation
        /// </summary>
        public string[] Values;

        /// <summary>
        /// Name of the Tab Completion scriptblock to use for validate set.
        /// </summary>
        public string TabCompletion;

        /// <summary>
        /// Custom error message to display
        /// </summary>
        public string ErrorMessage
        {
            get
            {
                if (!String.IsNullOrEmpty(ErrorString))
                    return Localization.LocalizationHost.Read(ErrorString);
                return _ErrorMessage;
            }
            set { _ErrorMessage = value; }
        }
        private string _ErrorMessage = "Cannot accept {0}, specify any of the following values: '{1}'";

        /// <summary>
        /// The stored localized string to use for error messages
        /// </summary>
        public string ErrorString;
        #endregion Public attribute properties

        /// <summary>
        /// Validates that each parameter argument matches the set of legal values
        /// </summary>
        /// <param name="element">object to validate</param>
        /// <exception cref="ValidationMetadataException">if <paramref name="element"/> is invalid</exception>
        protected override void ValidateElement(object element)
        {
            if (element == null)
            {
                throw new ValidationMetadataException("ArgumentIsEmpty", null);
            }

            List<string> legalValues = new List<string>();
            foreach (string value in GetValues())
                legalValues.Add(value.Trim("'".ToCharArray()));

            if (legalValues.Any(e => String.Equals(e, element.ToString(), StringComparison.OrdinalIgnoreCase)))
                return;
            
            throw new ValidationMetadataException(String.Format(ErrorMessage, element, String.Join(", ", legalValues)));
        }

        /// <summary>
        /// Empty constructor for other attributes
        /// </summary>
        public PsfValidateSetAttribute()
        {
            
        }

        /// <summary>
        /// Returns the values provided by the options specified.
        /// </summary>
        /// <returns>The legal values you may provide.</returns>
        public string[] GetValues()
        {
            if (Values != null && Values.Length > 0)
                return Values;

            if (ScriptBlock != null)
            {
                List<string> results = new List<string>();
                foreach (object item in ScriptBlock.Invoke())
                    if (item != null)
                        results.Add(item.ToString());
                return results.ToArray();
            }

            if (TabExpansion.TabExpansionHost.Scripts.ContainsKey(TabCompletion.ToLower()))
            {
                return TabExpansion.TabExpansionHost.Scripts[TabCompletion.ToLower()].Invoke();
            }

            return new string[0];
        }
    }
}
