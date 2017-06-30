using System;

namespace PSFramework.Utility
{
    /// <summary>
    /// Contains static resources of various kinds. Primarily for internal consumption.
    /// </summary>
    public static class UtilityHost
    {
        /// <summary>
        /// The ID for the primary (or front end) Runspace. Used for stuff that should only happen on the user-runspace.
        /// </summary>
        public static Guid PrimaryRunspace;
    }
}
