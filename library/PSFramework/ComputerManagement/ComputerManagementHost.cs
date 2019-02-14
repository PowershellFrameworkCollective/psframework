using System;
using System.Collections.Concurrent;

namespace PSFramework.ComputerManagement
{
    /// <summary>
    /// Host class containing static iresources for the computer management component
    /// </summary>
    public static class ComputerManagementHost
    {
        /// <summary>
        /// The timespan a PSSession may be idle before it is cleared for cleanup
        /// </summary>
        public static TimeSpan PSSessionIdleTimeout = new TimeSpan(0, 15, 0);

        /// <summary>
        /// List of known session types that can be used in a SessionContainer.
        /// </summary>
        public static ConcurrentDictionary<string, string> KnownSessionTypes = new ConcurrentDictionary<string, string>(StringComparer.InvariantCultureIgnoreCase);
    }
}
