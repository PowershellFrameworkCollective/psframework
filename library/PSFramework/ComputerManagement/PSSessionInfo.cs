using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.ComputerManagement
{
    /// <summary>
    /// Runtime information object on a PSSession connection. Used to implement session caching and disconnection.
    /// </summary>
    public class PSSessionInfo
    {
        /// <summary>
        /// The session object to inform upon
        /// </summary>
        public PSSession Session;

        /// <summary>
        /// The time this session object was last used
        /// </summary>
        public DateTime LastUsed;

        /// <summary>
        /// Shows whether the session has expired
        /// </summary>
        public bool IsExpired
        {
            get
            {
                return LastUsed.Add(ComputerManagementHost.PSSessionIdleTimeout) < DateTime.Now;
            }
        }

        /// <summary>
        /// Name of the remote session
        /// </summary>
        public string ComputerName
        {
            get
            {
                return Session.ComputerName;
            }
        }

        /// <summary>
        /// The current state of the session
        /// </summary>
        public RunspaceAvailability Availability
        {
            get
            {
                return Session.Availability;
            }
        }

        /// <summary>
        /// Resets the LastUsed timestamp, ensuring this session is not discarded prematurely.
        /// </summary>
        public void ResetTimestamp()
        {
            LastUsed = DateTime.Now;
        }

        /// <summary>
        /// Creates a session info object from a session object.
        /// </summary>
        /// <param name="Session">The session to wrap inside an info object</param>
        public PSSessionInfo(PSSession Session)
        {
            this.Session = Session;
            LastUsed = DateTime.Now;
        }
    }
}
