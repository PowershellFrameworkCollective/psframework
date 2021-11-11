using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using PSFramework.Utility;

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

        /// <summary>
        /// Clones the specified scriptblock maintaining its language mode.
        /// </summary>
        /// <param name="ScriptBlock">The Scriptblock to clone</param>
        /// <returns>A clone of the scriptblock with the languagemode intact</returns>
        public static ScriptBlock Clone(this ScriptBlock ScriptBlock)
        {
            ScriptBlock newBlock = null;
            Version minVersion = new Version(5, 1);
            if (PSFCore.PSFCoreHost.PSVersion >= minVersion)
            {
                newBlock = (ScriptBlock)UtilityHost.InvokePrivateMethod("Clone", ScriptBlock, null);
                UtilityHost.SetPrivateProperty("LanguageMode", newBlock, UtilityHost.GetPrivateProperty("LanguageMode", ScriptBlock));
            }
            else
                newBlock = (ScriptBlock)UtilityHost.InvokePrivateMethod("Clone", ScriptBlock, new object[] { false });
            return newBlock;
        }

        /// <summary>
        /// Resets the current scriptblock's sessionstate to the current runspace's global sessionstate.
        /// </summary>
        /// <param name="ScriptBlock">The scriptblock to globalize</param>
        /// <returns>The globalized scriptblock</returns>
        public static ScriptBlock ToGlobal(this ScriptBlock ScriptBlock)
        {
            UtilityHost.ImportScriptBlock(ScriptBlock, true);
            return ScriptBlock;
        }

        /// <summary>
        /// Resets the current scriptblock's sessionstate to the current runspace's current sessionstate.
        /// </summary>
        /// <param name="ScriptBlock">The scriptblock to import</param>
        /// <returns>The imported scriptblock</returns>
        public static ScriptBlock ToLocal(this ScriptBlock ScriptBlock)
        {
            UtilityHost.ImportScriptBlock(ScriptBlock);
            return ScriptBlock;
        }

        /// <summary>
        /// Resets the current scriptblock's sessionstate to either the current runspace's current sessionstate or its global sessionstate.
        /// </summary>
        /// <param name="ScriptBlock">The scriptblock to import</param>
        /// <param name="Global">Whether to import into the global sessionstate</param>
        /// <returns>The imported ScriptBlock</returns>
        public static ScriptBlock Import(this ScriptBlock ScriptBlock, bool Global = false)
        {
            UtilityHost.ImportScriptBlock(ScriptBlock, Global);
            return ScriptBlock;
        }
    }
}
