using System;

namespace PSFramework.License
{
    /// <summary>
    /// What kind of License is this? By default, a license is a free license allowing modification but requiring attribution.
    /// </summary>
    [Flags]
    public enum LicenseType
    {
        /// <summary>
        /// No special type is present
        /// </summary>
        Free = 1,

        /// <summary>
        /// The license is for a commercial product. This means you have to acquire use permission, such as software licenses, user CALs et al.
        /// </summary>
        Commercial = 2,

        /// <summary>
        /// Reusing this product requires no attribution. Just use it and call it your own.
        /// </summary>
        NoAttribution = 4,

        /// <summary>
        /// This product may be used, but must not be modified in any way.
        /// </summary>
        NoModify = 8,
    }
}