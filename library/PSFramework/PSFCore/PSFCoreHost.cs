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
    }
}
