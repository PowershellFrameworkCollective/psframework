using System;
using System.Linq;
using System.Management.Automation;

namespace PSFramework.Validation
{
    /// <summary>
    /// Validation attribute that tests a scriptblock's language mode.
    /// </summary>
    public class PsfValidateLanguageMode : ValidateEnumeratedArgumentsAttribute
    {
        /// <summary>
        /// The legal language modes, defaults to FullLanguage
        /// </summary>
        public PSLanguageMode[] Modes = new PSLanguageMode[] { PSLanguageMode.FullLanguage };

        /// <summary>
        /// Validation routine used by the engine
        /// </summary>
        /// <param name="element">The object to validate must be a scriptblock.</param>
        protected override void ValidateElement(object element)
        {
            if (element == null)
                throw new ValidationMetadataException(String.Format(Localization.LocalizationHost.Read("PSFramework.Assembly.Validation.Generic.ArgumentIsEmpty", null)));

            PSFCore.PSFCoreHost.WriteDebug("PsfValidateLanguagemode input", element);

            if ((element as ScriptBlock) == null)
                throw new ArgumentException(Localization.LocalizationHost.Read("PSFramework.Assembly.Validation.LanguageMode.NotAScriptBlock", new object[] { element }));

            ScriptBlock script = element as ScriptBlock;
            
            PSLanguageMode modeDetected = (PSLanguageMode)Utility.UtilityHost.GetPrivateProperty("LanguageMode", script);
            if (Modes.Contains(modeDetected))
                return;

            // FL requirement will not be met in AuditMode
            if (Modes.Contains(PSLanguageMode.FullLanguage) && modeDetected == PSLanguageMode.ConstrainedLanguage && IsAuditMode())
                return;

            throw new ArgumentException(Localization.LocalizationHost.Read("PSFramework.Assembly.Validation.LanguageMode.BadMode", new object[] { String.Join(",", Modes), modeDetected }));
        }

        /// <summary>
        /// Creates a default instance, validating for full language.
        /// </summary>
        public PsfValidateLanguageMode() { }

        /// <summary>
        /// Creates a custom instance, validating for the specified modes.
        /// </summary>
        /// <param name="Modes">The modes to test against.</param>
        public PsfValidateLanguageMode(PSLanguageMode[] Modes)
        {
            this.Modes = Modes;
        }


        private bool IsAuditMode()
        {
            // This wrapping is required to support older PS versions that do not yet contain the security namespace.
            // This might include older PS5.1 versions.
            // Methods using unknown classes / namespaces fail on invoke.
            try { return _IsAuditModeInternal(); }
            catch {  return false; }
        }

        private bool _IsAuditModeInternal()
        {
            return System.Management.Automation.Security.SystemPolicy.GetSystemLockdownPolicy() == System.Management.Automation.Security.SystemEnforcementMode.Audit;
        }
    }
}
