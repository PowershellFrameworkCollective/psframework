using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Extension
{
    /// <summary>
    /// Class that extends the scriptblock type
    /// </summary>
    public static class ScriptBlockExt
    {
        /// <summary>
        /// Implements the internal copy of DoInvokeReturnAsIs
        /// </summary>
        /// <param name="ScriptBlock">The scriptblock to execute</param>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="ErrorHandlingBehavior">How to handle errors. 2 should be the default</param>
        /// <param name="DollerUnder">The value to make available as $_</param>
        /// <param name="Input">The value to make available to $input</param>
        /// <param name="ScriptThis">The value to make available as $this</param>
        /// <param name="Args">The value to make available as $args</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public static object DoInvokeReturnAsIs(this ScriptBlock ScriptBlock, bool UseLocalScope, int ErrorHandlingBehavior, object DollerUnder, object Input, object ScriptThis, object[] Args)
        {
            object[] arguments = new object[] { UseLocalScope, ErrorHandlingBehavior, DollerUnder, Input, ScriptThis, Args };
            Type type = ScriptBlock.GetType();
            MethodInfo method = type.GetMethod("DoInvokeReturnAsIs", BindingFlags.NonPublic | BindingFlags.Instance);
            return method.Invoke(ScriptBlock, arguments);
        }
    }
}
