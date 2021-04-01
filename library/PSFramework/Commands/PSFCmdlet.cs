using PSFramework.Extension;
using PSFramework.FlowControl;
using PSFramework.Message;
using PSFramework.Meta;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;

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
        internal static string MessageScript = @"
param (
	$____PSF____Message,
	$____PSF____Level,
	$____PSF____FunctionName,
	$____PSF____ModuleName,
	$____PSF____File,
	$____PSF____Line,
	$____PSF____Tag,
	$____PSF____Target,
    $____PSF____Data
)
Write-PSFMessage -Message $____PSF____Message -Level $____PSF____Level -FunctionName $____PSF____FunctionName -ModuleName $____PSF____ModuleName -Tag $____PSF____Tag -File $____PSF____File -Line $____PSF____Line -Target $____PSF____Target -Data $____PSF____Data
";

        /// <summary>
        /// Access a scriptblock that can be used to write a message
        /// </summary>
        internal static string LocalizedMessageScript = @"
param (
	$____PSF____String,
	$____PSF____StringValues,
	$____PSF____Level,
	$____PSF____FunctionName,
	$____PSF____ModuleName,
	$____PSF____File,
	$____PSF____Line,
	$____PSF____Tag,
	$____PSF____Target,
    $____PSF____Data
)
Write-PSFMessage -String $____PSF____String -StringValues $____PSF____StringValues -Level $____PSF____Level -FunctionName $____PSF____FunctionName -ModuleName $____PSF____ModuleName -Tag $____PSF____Tag -File $____PSF____File -Line $____PSF____Line -Target $____PSF____Target -Data $____PSF____Data
";

        internal static string StopFunctionScript = @"
param (
	$__PSFramework__Message,
	
	$__PSFramework__Exception,
	
	$__PSFramework__Target,
	
	$__PSFramework__FunctionName,
	
	$__PSFramework__ModuleName,
	
	$__PSFramework__File,
	
	$__PSFramework__Line,
	
	$__PSFramework__Tag,
	
	$__PSFramework__Cmdlet,
	
	$__PSFramework__EnableException
)

$paramStopPSFFunction = @{
	Message		    = $__PSFramework__Message
	Target		    = $__PSFramework__Target
	FunctionName    = $__PSFramework__FunctionName
	ModuleName	    = $__PSFramework__ModuleName
	File		    = $__PSFramework__File
	Line		    = $__PSFramework__Line
	Cmdlet		    = $__PSFramework__Cmdlet
	EnableException = $__PSFramework__EnableException
	StepsUpward	    = -1
}
if ($__PSFramework__Tag) { $paramStopPSFFunction['Tag'] = $__PSFramework__Tag }
if ($__PSFramework__Exception) { $paramStopPSFFunction['Exception'] = $__PSFramework__Exception }
Stop-PSFFunction @paramStopPSFFunction
return
";
        internal static string LocalizedStopFunctionScript = @"
param (
	$__PSFramework__String,
	
	$__PSFramework__StringValues,
	
	$__PSFramework__Exception,
	
	$__PSFramework__Target,
	
	$__PSFramework__FunctionName,
	
	$__PSFramework__ModuleName,
	
	$__PSFramework__File,
	
	$__PSFramework__Line,
	
	$__PSFramework__Tag,
	
	$__PSFramework__Cmdlet,
	
	$__PSFramework__EnableException
)

$paramStopPSFFunction = @{
	String		    = $__PSFramework__String
	Target		    = $__PSFramework__Target
	FunctionName    = $__PSFramework__FunctionName
	ModuleName	    = $__PSFramework__ModuleName
	File		    = $__PSFramework__File
	Line		    = $__PSFramework__Line
	Cmdlet		    = $__PSFramework__Cmdlet
	EnableException = $__PSFramework__EnableException
	StepsUpward	    = -1
}
if ($__PSFramework__Tag) { $paramStopPSFFunction['Tag'] = $__PSFramework__Tag }
if ($__PSFramework__Exception) { $paramStopPSFFunction['Exception'] = $__PSFramework__Exception }
if ($__PSFramework__StringValues) { $paramStopPSFFunction['StringValues'] = $__PSFramework__StringValues }
Stop-PSFFunction @paramStopPSFFunction
return
";

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
        /// Do a rich invocation of the specified scriptblock
        /// </summary>
        /// <param name="ScriptCode">The scriptblock to execute</param>
        /// <param name="UseLocalScope">Whether a new scope should be created for this</param>
        /// <param name="DollerUnder">The value to make available as $_</param>
        /// <param name="Input">The value to make available to $input</param>
        /// <param name="ScriptThis">The value to make available as $this</param>
        /// <param name="Args">The value to make available as $args</param>
        /// <returns>Whatever output this scriptblock generates</returns>
        public object Invoke(string ScriptCode, bool UseLocalScope, object DollerUnder, object Input, object ScriptThis, object[] Args)
        {
            ScriptBlock script = ScriptBlock.Create(ScriptCode);
            return script.DoInvokeReturnAsIs(UseLocalScope, 2, DollerUnder, Input, ScriptThis, Args);
        }

        /// <summary>
        /// Returns the caller CallStackFrame item
        /// </summary>
        /// <param name="Level">How many levels to peek into the callstack</param>
        /// <returns>Returns the caller CallStackFrame item</returns>
        public CallStackFrame GetCaller(int Level = 0)
        {
            IEnumerable<CallStackFrame> callStack = Utility.UtilityHost.Callstack;
            CallStackFrame callerFrame = null;
            if (callStack.Count() > Level)
                callerFrame = callStack.ElementAt(Level);
            return callerFrame;
        }

        /// <summary>
        /// Returns the caller information the specified levels upstack
        /// </summary>
        /// <param name="Level">How many levels to peek into the callstack</param>
        /// <returns>The caller information of the specified level</returns>
        public CallerInfo GetCallerInfo(int Level = 0)
        {
            CallerInfo result = new CallerInfo(null);

            IEnumerable<CallStackFrame> callStack = Utility.UtilityHost.Callstack;
            if (callStack.Count() > Level)
                result = new CallerInfo(callStack.ElementAt(Level));

            return result;
        }

        /// <summary>
        /// Checks whether a certain feature flag applies or not to the current execution.
        /// </summary>
        /// <param name="Name">The name of the feature to check.</param>
        /// <returns>Whether the flag is enabled</returns>
        public bool TestFeature(string Name)
        {
            return Feature.FeatureHost.ReadFlag(Name, GetCallerInfo().CallerModule);
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
        /// <param name="Data">Add additional metadata to the message written</param>
        public void WriteMessage(string Message, MessageLevel Level, string FunctionName, string ModuleName, string File, int Line, string[] Tag, object Target, Hashtable Data = null)
        {
            object[] arguments = new object[] { Message, Level, FunctionName, ModuleName, File, Line, Tag, Target, Data };
            Invoke(MessageScript, false, null, null, null, arguments);
        }

        /// <summary>
        /// Write a message using the PSFramework. Executed as scriptblock, so the current runspace must not be occupied elseways
        /// </summary>
        /// <param name="String">The localized string to write</param>
        /// <param name="StringValues">The values to format into the localized string</param>
        /// <param name="Level">The level to write it at</param>
        /// <param name="FunctionName">The name of the function / cmdlet to assume</param>
        /// <param name="ModuleName">The name of the module to assume</param>
        /// <param name="File">The file this message was written from</param>
        /// <param name="Line">The line in the file this message was written from</param>
        /// <param name="Tag">Tags to attach to this message</param>
        /// <param name="Target">A target object to specify</param>
        /// <param name="Data">Add additional metadata to the message written</param>
        public void WriteLocalizedMessage(string String, object[] StringValues, MessageLevel Level, string FunctionName, string ModuleName, string File, int Line, string[] Tag, object Target, Hashtable Data = null)
        {
            object[] arguments = new object[] { String, StringValues, Level, FunctionName, ModuleName, File, Line, Tag, Target, Data };
            Invoke(LocalizedMessageScript, false, null, null, null, arguments);
        }

        /// <summary>
        /// Stops the current command. Sets the stopping flag for non-terminal interruption.
        /// </summary>
        /// <param name="Message">The message to write as an error</param>
        /// <param name="Error">An exception object to include in the message system</param>
        /// <param name="Target">A target object to specify</param>
        /// <param name="FunctionName">The name of the function / cmdlet to assume</param>
        /// <param name="ModuleName">The name of the module to assume</param>
        /// <param name="File">The file this message was written from</param>
        /// <param name="Line">The line in the file this message was written from</param>
        /// <param name="Tag">Tags to attach to this message</param>
        /// <param name="EnableException">Whether the command should terminate in fire and death and terminating exceptions</param>
        public void StopCommand(string Message, Exception Error, object Target, string FunctionName, string ModuleName, string File, int Line, string[] Tag, bool EnableException = true)
        {
            object[] arguments = new object[] { Message, Error, Target, FunctionName, ModuleName, File, Line, Tag, this, EnableException };
            IsStopping = true;
            Invoke(StopFunctionScript, false, null, null, null, arguments);
        }

        /// <summary>
        /// Stops the current command. Sets the stopping flag for non-terminal interruption.
        /// </summary>
        /// <param name="String">The localized string to write</param>
        /// <param name="StringValues">The values to format into the localized string</param>
        /// <param name="Error">An exception object to include in the message system</param>
        /// <param name="Target">A target object to specify</param>
        /// <param name="FunctionName">The name of the function / cmdlet to assume</param>
        /// <param name="ModuleName">The name of the module to assume</param>
        /// <param name="File">The file this message was written from</param>
        /// <param name="Line">The line in the file this message was written from</param>
        /// <param name="Tag">Tags to attach to this message</param>
        /// <param name="EnableException">Whether the command should terminate in fire and death and terminating exceptions</param>
        public void StopLocalizedCommand(string String, object[] StringValues, Exception Error, object Target, string FunctionName, string ModuleName, string File, int Line, string[] Tag, bool EnableException = true)
        {
            object[] arguments = new object[] { String, StringValues, Error, Target, FunctionName, ModuleName, File, Line, Tag, this, EnableException };
            IsStopping = true;
            Invoke(LocalizedStopFunctionScript, false, null, null, null, arguments);
        }

        /// <summary>
        /// Whether the command has been set to terminate by StopCommand. Use when supporting EnableException
        /// </summary>
        public bool IsStopping;

        /// <summary>
        /// Invokes all applicable callback scripts.
        /// </summary>
        /// <param name="Data">Data to send to the callback scriptblocks</param>
        /// <param name="EnableException">Whether a failed callback scriptblock fails this command in fire and terminating exception.</param>
        public void InvokeCallback(object Data, bool EnableException = true)
        {
            try { CallbackHost.Invoke(new Meta.CallerInfo(GetCaller()), this, Data); }
            catch (CallbackException e) { StopLocalizedCommand("PSFramework.Assembly.Callback.Failed", new object[] { e.Callback.Name }, e, null, MyInvocation.MyCommand.Name, MyInvocation.MyCommand.ModuleName, "<unknown>", 0, new string[] { "callback", "error" }, EnableException); }
        }
    }
}
