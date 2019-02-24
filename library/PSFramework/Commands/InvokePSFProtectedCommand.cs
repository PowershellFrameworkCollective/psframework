using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Commands
{
    /// <summary>
    /// A wrapper that will execute the specified scriptblock in a safe manner
    /// </summary>
    [Cmdlet("Invoke", "PSFProtectedCommand", SupportsShouldProcess = true)]
    public class InvokePSFProtectedCommand : PSFCmdlet
    {
        #region Parameters
        /// <summary>
        /// The scriptblock to execute.
        /// </summary>
        [Parameter(Mandatory = true)]
        public ScriptBlock ScriptBlock;

        /// <summary>
        /// Description of the action to perform
        /// </summary>
        [Parameter(Mandatory = true, ParameterSetName = "Message")]
        public string Action;

        /// <summary>
        /// A string to use localized message for the prompt
        /// </summary>
        [Parameter(Mandatory = true, ParameterSetName = "String")]
        public string ActionString;

        /// <summary>
        /// Values to format into the localized string
        /// </summary>
        [Parameter(ParameterSetName = "String")]
        public object[] ActionStringValues = new object[10];

        /// <summary>
        /// The target to perform the action against
        /// </summary>
        [Parameter()]
        public object Target;

        /// <summary>
        /// Whether to trigger a terminating exception in case the scriptblock errors out.
        /// Will be picked up automatically if not specified.
        /// </summary>
        [Parameter()]
        public bool EnableException;

        /// <summary>
        /// The cmdlet object to use for triggering terminating errors.
        /// Will be picked up automatically if not specified.
        /// </summary>
        [Parameter()]
        public PSCmdlet PSCmdlet;

        /// <summary>
        /// Triggers the calling of 'continue' in case of error
        /// </summary>
        [Parameter()]
        public SwitchParameter Continue;
        #endregion Parameters

        #region Private Fields
        /// <summary>
        /// Information on the calling command, including name, module, file and line.
        /// </summary>
        private Meta.CallerInfo _Caller;

        /// <summary>
        /// The message to print when prompting
        /// </summary>
        private string _Message
        {
            get
            {
                if (!String.IsNullOrEmpty(Action))
                    return Action;
                return Localization.LocalizationHost.ReadLog(_Caller.CallerModule, ActionString, ActionStringValues);
            }
        }

        /// <summary>
        /// Error message to post when execution fails
        /// </summary>
        private string _ErrorMessage
        {
            get
            {
                return Localization.LocalizationHost.ReadLog("PSFramework", "FlowControl.Invoke-PSFProtectedCommand.Failed", new object[] { _Message });
            }
        }
        #endregion Private Fields

        #region Cmdlet Implementation
        /// <summary>
        /// Prepare runtime information, such as calling command or cmdlet object
        /// </summary>
        protected override void BeginProcessing()
        {
            if (PSCmdlet == null)
                PSCmdlet = (PSCmdlet)GetVariableValue("PSCmdlet");

            _Caller = new Meta.CallerInfo(GetCaller());

            if (!MyInvocation.BoundParameters.ContainsKey("EnableException") && Feature.FeatureHost.ReadModuleFlag("PSFramework.InheritEnableException", _Caller.CallerModule))
                EnableException = LanguagePrimitives.IsTrue(GetVariableValue("EnableException"));
        }

        /// <summary>
        /// Perform the actual logic
        /// </summary>
        protected override void ProcessRecord()
        {
            bool test = PSCmdlet.ShouldProcess(LanguagePrimitives.ConvertTo<string>(Target), _Message);
            if (test)
                WriteMessage(Localization.LocalizationHost.ReadLog("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Confirmed", new object[] { _Message }), Message.MessageLevel.SomewhatVerbose, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, null, Target);
            else
            {
                WriteMessage(Localization.LocalizationHost.ReadLog("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Denied", new object[] { _Message }), Message.MessageLevel.SomewhatVerbose, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, null, Target);
                return;
            }

            try
            {
                WriteObject(PSCmdlet.InvokeCommand.InvokeScript(false, ScriptBlock, null, null));
            }
            catch (Exception e)
            {
                ScriptBlock errorBlock = ScriptBlock.Create(@"
param (
    $__PSFramework__Message,

    $__PSFramework__Exception,

    $__PSFramework__Target,

    $__PSFramework__Continue,

    $__PSFramework__FunctionName,

    $__PSFramework__ModuleName,

    $__PSFramework__File,

    $__PSFramework__Line,

    $__PSFramework__Cmdlet,

    $__PSFramework__EnableException
)

Stop-PSFFunction -Message $__PSFramework__Message -Exception $__PSFramework__Exception -Target $__PSFramework__Target -Continue:$__PSFramework__Continue -FunctionName $__PSFramework__FunctionName -ModuleName $__PSFramework__ModuleName -File $__PSFramework__File -Line $__PSFramework__Line -Cmdlet $__PSFramework__Cmdlet -EnableException $__PSFramework__EnableException -StepsUpward 1
return
");
                object[] arguments = new object[] { _ErrorMessage, e, Target, Continue, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, PSCmdlet, EnableException };
                PSCmdlet.InvokeCommand.InvokeScript(false, errorBlock, null, arguments);                
            }
        }
        #endregion Cmdlet Implementation
    }
}
