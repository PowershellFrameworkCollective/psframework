using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Meta
{
    /// <summary>
    /// Helper Class parsing CallStackInfo into something usable
    /// </summary>
    public class CallerInfo
    {
        /// <summary>
        /// The name of the function in the callstackframe
        /// </summary>
        public string CallerFunction = "<Unknown>";

        /// <summary>
        /// The name of the module the function in the callstackframe is part of
        /// </summary>
        public string CallerModule = "<Unknown>";

        /// <summary>
        /// The file this was called from
        /// </summary>
        public string CallerFile = "";

        /// <summary>
        /// The line in the file this was called from
        /// </summary>
        public int CallerLine = -1;

        /// <summary>
        /// Constructs the detailed information needed from a CallStackFrame
        /// </summary>
        /// <param name="Frame">The frame to parse</param>
        public CallerInfo(CallStackFrame Frame)
        {
            if (Frame == null)
                return;

            if (Frame.InvocationInfo == null)
                CallerFunction = Frame.FunctionName;
            else if (Frame.InvocationInfo.MyCommand == null)
                CallerFunction = Frame.InvocationInfo.InvocationName;
            else if (Frame.InvocationInfo.MyCommand.Name != "")
                CallerFunction = Frame.InvocationInfo.MyCommand.Name;
            else
                CallerFunction = Frame.FunctionName;

            if ((Frame.InvocationInfo != null) && (Frame.InvocationInfo.MyCommand != null) && (!String.IsNullOrEmpty(Frame.InvocationInfo.MyCommand.ModuleName)))
                CallerModule = Frame.InvocationInfo.MyCommand.ModuleName;

            if (!String.IsNullOrEmpty(Frame.Position.File))
                CallerFile = Frame.Position.File;

            CallerLine = Frame.Position.EndLineNumber;
        }
    }
}
