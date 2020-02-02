using System;
using System.Management.Automation;
using System.Text.RegularExpressions;

namespace PSFramework.Validation
{
    /// <summary>
    /// Validates that each parameter argument matches the RegexPattern
    /// </summary>
    [AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
    public sealed class PsfValidatePatternAttribute : ValidateEnumeratedArgumentsAttribute
    {
        /// <summary>
        /// Gets the Regex pattern to be used in the validation
        /// </summary>
        public string RegexPattern { get; }

        /// <summary>
        /// Gets or sets the Regex options to be used in the validation
        /// </summary>
        public RegexOptions Options { set; get; } = RegexOptions.IgnoreCase;

       /// <summary>
        /// Gets or sets the custom error message pattern that is displayed to the user.
        ///
        /// The text representation of the object being validated and the validating regex is passed as
        /// the first and second formatting parameters to the ErrorMessage formatting pattern.
        /// <example>
        /// [PsfValidatePattern("\s+", ErrorMessage="The text '{0}' did not pass validation of regex '{1}'")]
        /// </example>
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
        private string _ErrorMessage = "Failed to validate: {0} against pattern {1}";

        /// <summary>
        /// The stored localized string to use for error messages
        /// </summary>
        public string ErrorString;

        /// <summary>
        /// Validates that each parameter argument matches the RegexPattern
        /// </summary>
        /// <param name="element">object to validate</param>
        /// <exception cref="ValidationMetadataException">if <paramref name="element"/> is not a string
        ///  that matches the pattern
        ///  and for invalid arguments</exception>
        protected override void ValidateElement(object element)
        {
            if (element == null)
                throw new ValidationMetadataException(String.Format(Localization.LocalizationHost.Read("PSFramework.Assembly.Validation.Generic.ArgumentIsEmpty", null)));

            string objectString = element.ToString();
            Regex regex = null;
            regex = new Regex(RegexPattern, Options);
            Match match = regex.Match(objectString);
            if (!match.Success)
            {
                throw new ValidationMetadataException(String.Format(ErrorMessage, element, RegexPattern));
            }
        }

        /// <summary>
        /// Initializes a new instance of the PsfValidatePatternAttribute class
        /// </summary>
        /// <param name="regexPattern">Pattern string to match</param>
        /// <exception cref="ArgumentException">for invalid arguments</exception>
        public PsfValidatePatternAttribute(string regexPattern)
        {
            if (String.IsNullOrEmpty(regexPattern))
                throw new ArgumentNullException("Must specify a pattern!");
            
            RegexPattern = regexPattern;
        }
    }
}
