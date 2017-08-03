using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Logging
{
    /// <summary>
    /// Class containing all information/content needed for a logging provider
    /// </summary>
    public class Provider
    {
        /// <summary>
        /// Each logging provider has a name. Make sure it's unique
        /// </summary>
        public string Name;

        /// <summary>
        /// Whether the logging provider is enabled. Only when this is set to true will the logging script execute its events.
        /// </summary>
        public bool Enabled;

        /// <summary>
        /// The provider has had its initial runtime configuration (what is stored in the BeginEvent) applied.
        /// </summary>
        public bool Initialized;

        /// <summary>
        /// Event that is executed once per logging script execution, before logging occurs
        /// </summary>
        public ScriptBlock BeginEvent;

        /// <summary>
        /// Event that is executed each logging cycle, right before processing items.
        /// </summary>
        public ScriptBlock StartEvent;

        /// <summary>
        /// Event that is executed for each message written
        /// </summary>
        public ScriptBlock MessageEvent;

        /// <summary>
        /// Event that is executed for each error written
        /// </summary>
        public ScriptBlock ErrorEvent;

        /// <summary>
        /// Event that is executed once per logging cycle, after processing all message and error items.
        /// </summary>
        public ScriptBlock EndEvent;

        /// <summary>
        /// Final Event that is executed when stopping the logging script.
        /// </summary>
        public ScriptBlock FinalEvent;

        /// <summary>
        /// Scriptblock that adds additional parameters as needed to the Set-PSFLoggingProvider function
        /// </summary>
        public ScriptBlock DynamicParam;

        /// <summary>
        /// The configuration steps taken by the Set-PSFLoggingProvider function
        /// </summary>
        public ScriptBlock ConfigurationEvent;
    }
}
