using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Logging
{
    /// <summary>
    /// Container for errors that happened during logging
    /// </summary>
    public class Error
    {
        /// <summary>
        /// The logging provider that had the issue
        /// </summary>
        public string Provider;

        /// <summary>
        /// The specific instance of the logging provider that encounter the issue
        /// </summary>
        public string Instance;

        /// <summary>
        /// When it all happened
        /// </summary>
        public DateTime Timestamp;

        /// <summary>
        /// The error that happened
        /// </summary>
        public ErrorRecord ErrorRecord;

        /// <summary>
        /// Create a new error object
        /// </summary>
        /// <param name="Provider">Logging Provider with the issue</param>
        /// <param name="Instance">Instance of the Logging Provider with the issue</param>
        /// <param name="ErrorRecord">The Issue</param>
        public Error(string Provider, string Instance, ErrorRecord ErrorRecord)
        {
            this.Provider = Provider;
            this.Instance = Instance;
            this.ErrorRecord = ErrorRecord;
            Timestamp = DateTime.Now;
        }
    }
}
