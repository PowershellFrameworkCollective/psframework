using System.Collections.Concurrent;
using System.Collections.Generic;

namespace PSFramework.License
{
    /// <summary>
    /// Host class covering all static needs of the licensing system.
    /// </summary>
    public static class LicenseHost
    {
        /// <summary>
        /// The list containing all registered licenses.
        /// </summary>
        public static ConcurrentDictionary<string, License> Licenses = new ConcurrentDictionary<string, License>();

        #region Default methods
        /// <summary>
        /// Adds a new licenses to the list of registerd licenses.
        /// </summary>
        /// <param name="License">The license to add</param>
        public static void Add(License License)
        {
            string key = string.Format("{0}|{1}", License.Product, License.ProductVersion);
            Licenses[key] = License;
        }

        /// <summary>
        /// Removes all registered Licenses
        /// </summary>
        public static void Clear()
        {
            Licenses = new ConcurrentDictionary<string, License>();
        }

        /// <summary>
        /// Returns all registered licenses
        /// </summary>
        /// <returns>All registerd licenses</returns>
        public static ICollection<License> Get()
        {
            return Licenses.Values;
        }

        /// <summary>
        /// Returns a license that matches the specified license in content
        /// </summary>
        /// <param name="ReferenceLicense">The license based on which to search</param>
        /// <returns>The matching license object</returns>
        public static License Get(License ReferenceLicense)
        {
            License tempLicense = null;
            try { Licenses.TryGetValue(string.Format("{0}|{1}", ReferenceLicense.Product, ReferenceLicense.ProductVersion), out tempLicense); }
            catch { }
            return tempLicense;
        }

        /// <summary>
        /// Removes a spceific licenses from the list of registerd licenses
        /// </summary>
        /// <param name="License">License to remove</param>
        public static void Remove(License License)
        {
            string key = string.Format("{0}|{1}", License.Product, License.ProductVersion);
            License tempLicense;
            Licenses.TryRemove(key, out tempLicense);
        }
        #endregion Default methods
    }
}