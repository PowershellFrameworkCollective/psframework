using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Validation
{
    /// <summary>
    /// Validation attribute that ensures a parameter is only used in a given PS Version
    /// </summary>
    public class PsfValidatePSVersion : ValidateEnumeratedArgumentsAttribute
    {
        /// <summary>
        /// The minimum version required
        /// </summary>
        public Version Version;

        /// <summary>
        /// The name of the feature that can override this test
        /// </summary>
        public string FeatureName;

        /// <summary>
        /// Validation routine used by the engine
        /// </summary>
        /// <param name="element">The object to validate does not matter and is ignored.</param>
        protected override void ValidateElement(object element)
        {
            // If version is sufficient, no further thought needed
            if (PSFCore.PSFCoreHost.PSVersion >= Version)
                return;

            if (!String.IsNullOrEmpty(FeatureName) && Feature.FeatureHost.Features.ContainsKey(FeatureName))
                if (Feature.FeatureHost.ReadFlag(FeatureName, (new Meta.CallerInfo(Utility.UtilityHost.Callstack.First())).CallerModule))
                    return;

            throw new ValidationMetadataException(Localization.LocalizationHost.Read("PSFramework.Assembly.Validation.PSVersion.TooLow", new object[] { Version, PSFCore.PSFCoreHost.PSVersion }));
        }

        /// <summary>
        /// Create a new validation attribute with a preconfigured minimum version
        /// </summary>
        /// <param name="MinimumVersion">The minimum version required</param>
        public PsfValidatePSVersion(string MinimumVersion)
        {
            Version = Version.Parse(MinimumVersion);
        }

        /// <summary>
        /// Create a new validation attribute with a preconfigured minimum version
        /// </summary>
        /// <param name="MinimumVersion">The minimum version required</param>
        /// <param name="FeatureName">An optional featureflag that can override this validation</param>
        public PsfValidatePSVersion(string MinimumVersion, string FeatureName)
        {
            Version = Version.Parse(MinimumVersion);
            this.FeatureName = FeatureName;
        }
    }
}
