using PSFramework.Message;
using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.PSFCore
{
    /// <summary>
    /// Debug data container
    /// </summary>
    public class DebugData
    {
        /// <summary>
        /// TImestamp the data was created at
        /// </summary>
        public readonly DateTime Timestamp = DateTime.Now;

        /// <summary>
        /// Label for the data written
        /// </summary>
        public string Label;

        /// <summary>
        /// Data submitted by the writer
        /// </summary>
        public object Data;

        /// <summary>
        /// Callstack at the moment of the call
        /// </summary>
        public CallStack ScriptCallstack = new CallStack(UtilityHost.Callstack);

        /// <summary>
        /// Create debug information for troubleshooting purposes
        /// </summary>
        /// <param name="Data">The data to write</param>
        /// <param name="Label">A label to store with the data to better track its origin</param>
        public DebugData(string Label, object Data)
        {
            this.Label = Label;
            this.Data = Data;
        }
    }
}
