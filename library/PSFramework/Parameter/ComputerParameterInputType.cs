using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Parameter
{
    /// <summary>
    /// The kind of object that was bound to the parameter class
    /// </summary>
    public enum ComputerParameterInputType
    {
        /// <summary>
        /// The input object is just any non-special kind of input.
        /// </summary>
        Default = 0,

        /// <summary>
        /// The input object is a PowerShell Session object
        /// </summary>
        PSSession = 1,

        /// <summary>
        /// The input object is a live SMO Server object
        /// </summary>
        SMOServer = 2,

        /// <summary>
        /// The input object is a live cim session object
        /// </summary>
        CimSession = 3,

        /// <summary>
        /// The input object is a session container object, potentially containing live session objects of various types at the same time.
        /// </summary>
        Container = 4,
    }
}
