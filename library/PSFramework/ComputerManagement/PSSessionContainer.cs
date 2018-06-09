using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.ComputerManagement
{
    /// <summary>
    /// A class designed to contain PSSessionInfo objects
    /// </summary>
    public class PSSessionContainer : Dictionary<string, PSSessionInfo>
    {
        /// <summary>
        /// Creeates a session container dictionary, that is not opinionated about casing.
        /// </summary>
        public PSSessionContainer()
            : base(StringComparer.InvariantCultureIgnoreCase)
        {
            
        }

        /// <summary>
        /// Returns a list of all expired sessions
        /// </summary>
        /// <returns>The list of expired sessions</returns>
        public IEnumerable<PSSessionInfo> GetExpired()
        {
            return from a in Values where a.IsExpired select a;
        }

        /// <summary>
        /// Returns a list of all sessions that have broken (generally by having hit the hard wsman limits or the remote computer being down)
        /// </summary>
        /// <returns>The list of broken sessions.</returns>
        public IEnumerable<PSSessionInfo> GetBroken()
        {
            return from a in Values where a.Availability == RunspaceAvailability.None select a;
        }
    }
}
