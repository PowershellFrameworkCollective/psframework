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
        public static List<License> Licenses = new List<License>();

        #region Default methods
        /// <summary>
        /// Adds a new licenses to the list of registerd licenses.
        /// </summary>
        /// <param name="License">The license to add</param>
        public static void Add(License License)
        {
            Licenses.Add(License);

            // TODO: Add code to respect policy settings to log added licenses
        }

        /// <summary>
        /// Removes all registered Licenses
        /// </summary>
        public static void Clear()
        {
            Licenses = new List<License>();
        }

        /// <summary>
        /// Returns all registered licenses
        /// </summary>
        /// <returns>All registerd licenses</returns>
        public static List<License> Get()
        {
            return Licenses;
        }

        /// <summary>
        /// Removes a spceific licenses from the list of registerd licenses
        /// </summary>
        /// <param name="License">License to remove</param>
        public static void Remove(License License)
        {
            Licenses.Remove(License);
        }
        #endregion Default methods


    }
}