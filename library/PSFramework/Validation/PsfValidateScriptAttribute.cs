using System;
using System.Management.Automation;
using static PSFramework.Extension.ScriptBlockExt;

namespace PSFramework.Validation
{
    /// <summary>
    /// Class for validating against a script block.
    /// </summary>
    public class PsfValidateScriptAttribute : ValidateEnumeratedArgumentsAttribute
    {
        /// <summary>
        /// Gets or sets the custom error message that is displayed to the user.
        ///
        /// The item being validated and the validating scriptblock is passed as the first and second
        /// formatting argument.
        ///
        /// <example>
        /// [ValidateScript("$_ % 2", ErrorMessage = "The item '{0}' did not pass validation of script '{1}'")]
        /// </example>
        /// </summary>
        public string ErrorMessage { get; set; }

        /// <summary>
        /// Gets the scriptblock to be used in the validation
        /// </summary>
        public ScriptBlock ScriptBlock
        {
            get
            {
                if (!String.IsNullOrEmpty(ScriptBlockName))
                    return Utility.UtilityHost.ScriptBlocks[ScriptBlockName].ScriptBlock;
                return _ScriptBlock;
            }
            private set { _ScriptBlock = value; }
        }
        private ScriptBlock _ScriptBlock;

        /// <summary>
        /// Name of a stored scriptblock to use
        /// </summary>
        public string ScriptBlockName { get; private set; }

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

            object result = ScriptBlock.DoInvokeReturnAsIs(true, 2, element, null, null, new object[] { element });
            
            if (!LanguagePrimitives.IsTrue(result))
            {
                var errorMessageFormat = String.IsNullOrEmpty(ErrorMessage) ? "Error executing validation script: {0} against {{ {1} }}" : ErrorMessage;
                throw new ValidationMetadataException(String.Format(errorMessageFormat, element, ScriptBlock));
            }
        }

        /// <summary>
        /// Initializes a new instance of the ValidateScriptBlockAttribute class
        /// </summary>
        /// <param name="ScriptBlock">Scriptblock to match</param>
        /// <exception cref="ArgumentException">for invalid arguments</exception>
        public PsfValidateScriptAttribute(ScriptBlock ScriptBlock)
        {
            this.ScriptBlock = ScriptBlock ?? throw new ArgumentNullException("Need to specify a scriptblock!");
        }

        /// <summary>
        /// Initializes a new instance of the ValidateScriptBlockAttribute class
        /// </summary>
        public PsfValidateScriptAttribute(string ScriptBlockName)
        {
            this.ScriptBlockName = ScriptBlockName;
        }
    }
}
