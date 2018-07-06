using System;
using System.Collections.Generic;
using System.Management.Automation;

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
        #endregion Public attribute properties

        /// <summary>
        /// Validates that each parameter argument matches the scriptblock
        /// </summary>
        /// <param name="element">object to validate</param>
        /// <exception cref="ValidationMetadataException">if <paramref name="element"/> is invalid</exception>
        protected override void ValidateElement(object element)
        {
            if (element == null)
            {
                throw new ValidationMetadataException("ArgumentIsEmpty", null);
            }

            object result = ScriptBlock.Invoke(element);

            if (!LanguagePrimitives.IsTrue(result))
            {
                var errorMessageFormat = String.IsNullOrEmpty(ErrorMessage) ? "Error executing validation script: {0} against {{ {1} }}" : ErrorMessage;
                throw new ValidationMetadataException(String.Format(errorMessageFormat, element, ScriptBlock));
            }
        }

        /// <summary>
        /// Initializes a new instance of the ValidateSetAttribute class
        /// </summary>
        public PsfValidateSetAttribute()
        {
            
        }

        /// <summary>
        /// Returns the values provided by the options specified.
        /// </summary>
        /// <returns>The legal values you may provide.</returns>
        private string[] GetValues()
        {
            if (Values.Length > 0)
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
                TabExpansion.ScriptContainer container = TabExpansion.TabExpansionHost.Scripts[TabCompletion.ToLower()];
                return container.Invoke();
            }

            return new string[];
        }
    }
}
