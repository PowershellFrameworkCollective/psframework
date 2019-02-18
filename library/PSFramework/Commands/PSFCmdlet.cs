using PSFramework.Extension;
using PSFramework.Message;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Commands
{
    /// <summary>
    /// Base class for all PSFramework Cmdlets, offering some shared tooling
    /// </summary>
    public abstract class PSFCmdlet : PSCmdlet
    {
        /// <summary>
        /// Access a scriptblock that can be used to write a message
        /// </summary>
        internal static ScriptBlock MessageScript
        {
            get
            {
                if (_MessageScript == null)
                {
                    _MessageScript = ScriptBlock.Create(@"
param (
    $Message,
    $Level,
    $FunctionName,
    $ModuleName,
    $File,
    $Line,
    $Tag,
    $Target
)
Write-PSFMessage -Message $Message -Level $Level -FunctionName $FunctionName -ModuleName $ModuleName -Tag $Tag -File $File -Line $Line -Target $Target
");
                }
                return _MessageScript;
            }
        }
        private static ScriptBlock _MessageScript;

        /// <summary>
        /// Invokes a string of text-based scriptcode
        /// </summary>
        /// <param name="ScriptCode">The script code to execute</param>
        /// <returns>Returns whatever it will return</returns>
        public System.Collections.ObjectModel.Collection<PSObject> Invoke(string ScriptCode)
        {
            return InvokeCommand.InvokeScript(ScriptCode);
        }

        /// <summary>
        /// Do a rich invocation of the specified scriptblock
        /// </summary>
        /// <param name="ScriptBlock">The scriptblock to execute</param>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="DollerUnder">The value to make available as $_</param>
        /// <param name="Input">The value to make available to $input</param>
        /// <param name="ScriptThis">The value to make available as $this</param>
        /// <param name="Args">The value to make available as $args</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public object Invoke(ScriptBlock ScriptBlock, bool UseLocalScope, object DollerUnder, object Input, object ScriptThis, object[] Args)
        {
            return ScriptBlock.DoInvokeReturnAsIs(UseLocalScope, 2, DollerUnder, Input, ScriptThis, Args);
        }

        /// <summary>
        /// Returns the caller CallStackFrame item
        /// </summary>
        /// <returns>Returns the caller CallStackFrame item</returns>
        public CallStackFrame GetCaller()
        {
            IEnumerable<CallStackFrame> callStack = Utility.UtilityHost.Callstack;
            CallStackFrame callerFrame = null;
            if (callStack.Count() > 0)
                callerFrame = callStack.First();
            return callerFrame;
        }

        /// <summary>
        /// Write a message using the PSFramework. Executed as scriptblock, so the current runspace must not be occupied elseways
        /// </summary>
        /// <param name="Message">The message to write</param>
        /// <param name="Level">The level to write it at</param>
        /// <param name="FunctionName">The name of the function / cmdlet to assume</param>
        /// <param name="ModuleName">The name of the module to assume</param>
        /// <param name="File">The file this message was written from</param>
        /// <param name="Line">The line in the file this message was written from</param>
        /// <param name="Tag">Tags to attach to this message</param>
        /// <param name="Target">A target object to specify</param>
        public void WriteMessage(string Message, MessageLevel Level, string FunctionName, string ModuleName, string File, int Line, string[] Tag, object Target)
        {
            object[] arguments = new object[] { Message, Level, FunctionName, ModuleName, File, Line, Tag, Target };
            Invoke(MessageScript, false, null, null, null, arguments);
        }
    }
}
