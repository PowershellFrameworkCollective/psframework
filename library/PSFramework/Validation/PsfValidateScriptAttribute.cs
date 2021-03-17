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

        /// <summary>
        /// Gets the scriptblock to be used in the validation
        /// </summary>
        public ScriptBlock ScriptBlock
        {
            get
            {
                ScriptBlock tempScb;
                if (!String.IsNullOrEmpty(ScriptBlockName))
                    tempScb = Utility.UtilityHost.ScriptBlocks[ScriptBlockName].ScriptBlock;
                else
                    tempScb = _ScriptBlock;
                if (Global)
                    return tempScb.Clone().ToGlobal();
                return tempScb;
            }
            private set { _ScriptBlock = value; }
        }
        private ScriptBlock _ScriptBlock;

        /// <summary>
        /// Whether the scriptblock should be invoked as global scriptblock
        /// </summary>
        public bool Global
        {
            get
            {
                if (!String.IsNullOrEmpty(ScriptBlockName))
                    return Utility.UtilityHost.ScriptBlocks[ScriptBlockName].Global;
                return _Global;
            }
            set { _Global = value; }
        }
        private bool _Global;

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
                throw new ValidationMetadataException(Localization.LocalizationHost.Read("PSFramework.Assembly.Validation.Generic.ArgumentIsEmpty", null));
            if (ScriptBlock == null)
                throw new ValidationMetadataException(Localization.LocalizationHost.Read("PSFramework.Assembly.Validation.ScriptBlock.IsNull", null));

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
