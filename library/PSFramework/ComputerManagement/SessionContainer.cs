using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation.Runspaces;
using Microsoft.Management.Infrastructure;
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
        /// Converts the session container to PSSession, if one is included
        /// </summary>
        /// <param name="Container">The container from which to gather the PSSession</param>
        public static implicit operator PSSession(SessionContainer Container)
        {
            if (!Container.Connections.ContainsKey("PSSession"))
                throw new KeyNotFoundException(Localization.LocalizationHost.ReadLog("PSFramework.Assembly.ComputerManagement.SessionContainer.NoPSSessionKey"));

            return (PSSession)(Container.Connections["PSSession"]);
        }

        /// <summary>
        /// Converts the session container to CImSession, if one is included
        /// </summary>
        /// <param name="Container">The container from which to gather the CimSession</param>
        public static implicit operator CimSession(SessionContainer Container)
        {
            if (!Container.Connections.ContainsKey("CimSession"))
                throw new KeyNotFoundException(Localization.LocalizationHost.ReadLog("PSFramework.Assembly.ComputerManagement.SessionContainer.NoCimSessionKey"));

            return (CimSession)(Container.Connections["CimSession"]);
        }

        /// <summary>
        /// The default string representation
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            return ComputerName;
        }
    }
}
