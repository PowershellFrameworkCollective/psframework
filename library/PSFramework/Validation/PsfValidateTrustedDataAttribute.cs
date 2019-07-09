using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;
using System.Reflection;
using PSFramework.Utility;

namespace PSFramework.Validation
{
    /// <summary>
    /// Validation attribute that works equivalent to the ValidateTrustedDataAttribute, but can be used on PS3+ (for no effect on those).
    /// </summary>
    public class PsfValidateTrustedDataAttribute : ValidateArgumentsAttribute
    {
        /// <summary>
        /// Validates that the parameter argument is not untrusted
        /// </summary>
        /// <param name="arguments">Object to validate</param>
        /// <param name="engineIntrinsics">
        /// The engine APIs for the context under which the validation is being
        /// evaluated.
        /// </param>
        /// <exception cref="ValidationMetadataException">
        /// if the argument is untrusted.
        /// </exception>
        protected override void Validate(object arguments, EngineIntrinsics engineIntrinsics)
        {
            bool everConstrained = false;
            bool isFullLanguage = false;
            MethodInfo marked = null;
            try
            {
                object executionContextTLS = UtilityHost.GetExecutionContextFromTLS();
                everConstrained = (bool)UtilityHost.GetPrivateStaticProperty(executionContextTLS.GetType(), "HasEverUsedConstrainedLanguage");
                isFullLanguage = (PSLanguageMode) UtilityHost.GetPrivateProperty("LanguageMode", executionContextTLS) == PSLanguageMode.FullLanguage;
                marked = UtilityHost.GetPrivateStaticMethod(executionContextTLS.GetType(), "IsMarkedAsUntrusted");
            }
            catch { }

            if (everConstrained && isFullLanguage)
                if ((bool)marked.Invoke(null, BindingFlags.NonPublic | BindingFlags.Static, null, new object[] { arguments }, System.Globalization.CultureInfo.CurrentCulture))
                    throw new ValidationMetadataException(String.Format(Localization.LocalizationHost.Read("PSFramework.Assembly.Validation.UntrustedData"), arguments));
        }
    }
}
