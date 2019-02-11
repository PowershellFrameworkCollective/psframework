using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.ComputerManagement
{
    /// <summary>
    /// Container for multiple session objects, to pass through to internal commands
    /// </summary>
    public class SessionContainer
    {
        /// <summary>
        /// Name of the computer
        /// </summary>
        public string ComputerName;

        /// <summary>
        /// The connections payload. One connection per connection type.
        /// </summary>
        public Hashtable Connections = new Hashtable(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// The defautl string representation
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            return ComputerName;
        }
    }
}
