using PSFramework.FlowControl;
using PSFramework.Meta;
using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Commands
{
    /// <summary>
    /// Command executing callbacks in functions
    /// </summary>
    [Cmdlet("Invoke", "PSFCallback")]
    public class InvokePSFCallbackCommand : PSFCmdlet
    {
        /// <summary>
        /// Data to pass to the callback scriptblocks
        /// </summary>
        [Parameter()]
        public object Data;

        /// <summary>
        /// Whether to trigger a terminating exception in case the scriptblock errors out.
        /// Will be picked up automatically if not specified.
        /// </summary>
        [Parameter()]
        [TypeTransformation(typeof(Boolean))]
        public bool EnableException;

        /// <summary>
        /// The cmdlet object to use for triggering terminating errors.
        /// Will be picked up automatically if not specified.
        /// </summary>
        [Parameter()]
        public PSCmdlet PSCmdlet;

        /// <summary>
        /// Information on the calling command, including name, module, file and line.
        /// </summary>
        private Meta.CallerInfo _Caller;

        /// <summary>
        /// script used to write horrible errors on screen
        /// </summary>
        private string _ErrorScript = @"
param (
	$__PSFramework__Message,
	
	$__PSFramework__Exception,
	
	$__PSFramework__FunctionName,
	
	$__PSFramework__ModuleName,
	
	$__PSFramework__File,
	
	$__PSFramework__Line,
	
	$__PSFramework__Cmdlet,
	
	$__PSFramework__EnableException
)

$paramStopPSFFunction = @{
	Message		    = $__PSFramework__Message
	Exception	    = $__PSFramework__Exception
	FunctionName    = $__PSFramework__FunctionName
	ModuleName	    = $__PSFramework__ModuleName
	File		    = $__PSFramework__File
	Line		    = $__PSFramework__Line
	Cmdlet		    = $__PSFramework__Cmdlet
	EnableException = $__PSFramework__EnableException
	StepsUpward	    = 1
}
Stop-PSFFunction @paramStopPSFFunction
return
";

        /// <summary>
        /// Prepare runtime information, such as calling command or cmdlet object
        /// </summary>
        protected override void BeginProcessing()
        {
            if (PSCmdlet == null)
                PSCmdlet = (PSCmdlet)GetVariableValue("PSCmdlet");
            if (PSCmdlet == null)
                PSCmdlet = this;

            _Caller = GetCallerInfo();

            if (!MyInvocation.BoundParameters.ContainsKey("EnableException") && Feature.FeatureHost.ReadModuleFlag("PSFramework.InheritEnableException", _Caller.CallerModule))
                EnableException = LanguagePrimitives.IsTrue(GetVariableValue("EnableException"));
        }

        /// <summary>
        /// Invoke callbacks
        /// </summary>
        protected override void ProcessRecord()
        {
            try { CallbackHost.Invoke(GetCallerInfo(1), PSCmdlet, Data); }
            catch (CallbackException e) { Terminate(e); }
        }

        /// <summary>
        /// Kill command with maximum prejudice
        /// </summary>
        /// <param name="error">The error to terminate with</param>
        private void Terminate(CallbackException error)
        {
            ScriptBlock errorBlock = ScriptBlock.Create(_ErrorScript);
            object[] arguments = new object[] { $"Failed to execute callback {error.Callback.Name}", error, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, PSCmdlet, EnableException };
            PSCmdlet.InvokeCommand.InvokeScript(false, errorBlock, null, arguments);
        }
    }
}
