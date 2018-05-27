using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.FlowControl
{
    /// <summary>
    /// The powershell edition
    /// </summary>
    public enum PSEdition
    {
        /// <summary>
        /// The desktop edition of PowerShell - all editions 5.1 or below
        /// </summary>
        Desktop,

        /// <summary>
        /// .NET core based editions of PowerShell
        /// </summary>
        Core
    }
}
