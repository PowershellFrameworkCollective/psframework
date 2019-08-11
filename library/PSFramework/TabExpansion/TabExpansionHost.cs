using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Management.Automation;

namespace PSFramework.TabExpansion
{
    /// <summary>
    /// Class that handles the static fields supporting the ÜSFramework TabExpansion implementation
    /// </summary>
    public static class TabExpansionHost
    {
        #region State information
        /// <summary>
        /// Field containing the scripts that were registered.
        /// </summary>
        public static ConcurrentDictionary<string, ScriptContainer> Scripts = new ConcurrentDictionary<string, ScriptContainer>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The cache used by scripts utilizing TabExpansionPlusPlus for PSFramework
        /// </summary>
        public static Hashtable Cache
        {
            get
            {
                lock(_CacheLock)
                    return _Cache;
            }
            set
            {
                lock(_CacheLock)
                    _Cache = value;
            }
        }
        private static Hashtable _Cache = new Hashtable(StringComparer.InvariantCultureIgnoreCase);
        private static readonly object _CacheLock = new object();
        #endregion State information

        #region Resources for individual tab completions
        /// <summary>
        /// Dictionary containing a list of hashtables to explicitly add properties when completing for specific output types.
        /// Entries must have three properties:
        /// - Name (Name of Property)
        /// - Type (Type, not Typename, of the property. May be empty)
        /// - TypeKnown (Boolean, whether the type is known)
        /// Used by the Tab Completion: PSFramework-Input-ObjectProperty
        /// </summary>
        public static ConcurrentDictionary<string, object[]> InputCompletionTypeData = new ConcurrentDictionary<string, object[]>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Dictionary containing a list of hashtables to explicitly add properties when completing for specific commands
        /// Entries must have three properties:
        /// - Name (Name of Property)
        /// - Type (Type, not Typename, of the property. May be empty)
        /// - TypeKnown (Boolean, whether the type is known)
        /// Used by the Tab Completion: PSFramework-Input-ObjectProperty
        /// </summary>
        public static ConcurrentDictionary<string, object[]> InputCompletionCommandData = new ConcurrentDictionary<string, object[]>(StringComparer.InvariantCultureIgnoreCase);
        #endregion Resources for individual tab completions
    }
}
