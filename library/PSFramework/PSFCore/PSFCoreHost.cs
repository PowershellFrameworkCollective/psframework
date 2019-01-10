using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.PSFCore
{
    /// <summary>
    /// Class containing static settings and values used to globally handle things
    /// </summary>
    public static class PSFCoreHost
    {
        /// <summary>
        /// Whether the current console is in unattended mode
        /// </summary>
        public static bool Unattended = false;

        /// <summary>
        /// The path to where the module was imported from
        /// </summary>
        public static string ModuleRoot
        {
            get { return _ModuleRoot; }
            set
            {
                if (String.IsNullOrEmpty(_ModuleRoot))
                    _ModuleRoot = value;
            }
        }
        private static string _ModuleRoot;

        /// <summary>
        /// Initializes the PSFramework library.
        /// Required for some components to work correctly.
        /// </summary>
        public static void Initialize()
        {
            if (_Initialized)
                return;
            _Initialized = true;

            // Initialization logic goes here
        }
        private static bool _Initialized = false;

        /// <summary>
        /// Reverses the initialization of the PSFramework library.
        /// Should be called when destroying the main runspace
        /// </summary>
        public static void Uninitialize()
        {
            if (!_Initialized)
                return;

            // De-Initiialization logic goes here

            _Initialized = false;
        }
    }
}
