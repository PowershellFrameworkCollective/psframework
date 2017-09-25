using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.TabExpansion
{
    /// <summary>
    /// Whether the user wants to use simple tepp, full tepp or auto-detect
    /// </summary>
    public enum TeppScriptMode
    {
        /// <summary>
        /// Simple mode. The scriptblock provided by the user is expected to provide a list of strings. All the rest is processed by the system
        /// </summary>
        Simple = 1,

        /// <summary>
        /// In full mode, the user is expected to provide the full TEPP scriptblock.
        /// </summary>
        Full = 2,

        /// <summary>
        /// In Auto-Detect mode, the system detects, whether the user intended to provide a simple mode or full mode script. This is determined by whether the scriptblock contains a parameter block or not.
        /// </summary>
        Auto = 4
    }
}
