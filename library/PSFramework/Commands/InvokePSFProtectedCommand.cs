using PSFramework.Parameter;
using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading;
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
        [TypeTransformation(typeof(Boolean))]
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

        /// <summary>
        /// The label in which to continue
        /// </summary>
        [Parameter()]
        public string ContinueLabel;

        /// <summary>
        /// Tags to add to the messages
        /// </summary>
        [Parameter()]
        public string[] Tag;

        /// <summary>
        /// How many times shall an attempt be made to try again when execution fails?
        /// </summary>
        [Parameter()]
        public int RetryCount = 0;

        /// <summary>
        /// How long to wait inbetween retries?
        /// </summary>
        [Parameter()]
        public TimeSpanParameter RetryWait = new TimeSpanParameter(5);

        /// <summary>
        /// Only retry on errors of the following types
        /// </summary>
        [Parameter()]
        public string[] RetryErrorType = new string[0];

        /// <summary>
        /// Only when this scriptblock returns $true will it try again.
        /// The scriptblock receives argument: The exception object.
        /// </summary>
        [Parameter()]
        public ScriptBlock RetryCondition;
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
                return Localization.LocalizationHost.Read(_Caller.CallerModule, ActionString, ActionStringValues);
            }
        }

        /// <summary>
        /// Error message to post when execution fails
        /// </summary>
        private string _ErrorMessage
        {
            get
            {
                return Localization.LocalizationHost.Read("PSFramework", "FlowControl.Invoke-PSFProtectedCommand.Failed", new object[] { _Message });
            }
        }

        /// <summary>
        /// script used to write horrible errors on screen
        /// </summary>
        private string _ErrorScript = @"
param (
	$__PSFramework__Message,
	
	$__PSFramework__Exception,
	
	$__PSFramework__Target,
	
	$__PSFramework__Continue,
	
	$__PSFramework__ContinueLabel,
	
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
	Target		    = $__PSFramework__Target
	Continue	    = $__PSFramework__Continue
	FunctionName    = $__PSFramework__FunctionName
	ModuleName	    = $__PSFramework__ModuleName
	File		    = $__PSFramework__File
	Line		    = $__PSFramework__Line
	Cmdlet		    = $__PSFramework__Cmdlet
	EnableException = $__PSFramework__EnableException
	StepsUpward	    = 1
}
if ($__PSFramework__ContinueLabel) { $paramStopPSFFunction['ContinueLabel'] = $__PSFramework__ContinueLabel }
Stop-PSFFunction @paramStopPSFFunction
return
";
        #endregion Private Fields

        #region Cmdlet Implementation
        /// <summary>
        /// Prepare runtime information, such as calling command or cmdlet object
        /// </summary>
        protected override void BeginProcessing()
        {
            if (PSCmdlet == null)
                PSCmdlet = (PSCmdlet)GetVariableValue("PSCmdlet");
            if (PSCmdlet == null)
                PSCmdlet = this;

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
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Confirmed", new object[] { _Message }), Message.MessageLevel.SomewhatVerbose, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
            else
            {
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Denied", new object[] { _Message }), Message.MessageLevel.SomewhatVerbose, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
                return;
            }

            int countAttempted = 0;
            while (countAttempted <= RetryCount)
            {
                countAttempted++;

                try
                {
                    object result = PSCmdlet.InvokeCommand.InvokeScript(false, ScriptBlock, null, null);
                    WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Success", new object[] { _Message }), Message.MessageLevel.SomewhatVerbose, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
                    if (result != null)
                        WriteObject(result);
                    return;
                }
                catch (Exception e)
                {
                    Exception tempError = e;
                    if (tempError is ActionPreferenceStopException)
                        tempError = ((ActionPreferenceStopException)tempError).ErrorRecord.Exception;

                    if (RetryCount == 0)
                    {
                        Terminate(tempError);
                        return;
                    }
                    if (RetryCondition != null && !LanguagePrimitives.IsTrue(Invoke(RetryCondition, true, tempError, tempError, null, new object[] { Target })))
                    {
                        Terminate(tempError);
                        return;
                    }
                    if (RetryErrorType.Length > 0 && !RetryErrorType.Contains(tempError.GetType().FullName, StringComparer.InvariantCultureIgnoreCase))
                    {
                        Terminate(tempError);
                        return;
                    }
                    if (countAttempted > RetryCount)
                    {
                        Terminate(tempError);
                        return;
                    }
                }
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Retry", new object[] { countAttempted, (RetryCount + 1), _Message }), Message.MessageLevel.SomewhatVerbose, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
                Thread.Sleep(RetryWait);
            }
            
        }
        #endregion Cmdlet Implementation

        private void Terminate(Exception error)
        {
            ScriptBlock errorBlock = ScriptBlock.Create(_ErrorScript);
            object[] arguments = new object[] { _ErrorMessage, error, Target, Continue, ContinueLabel, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, PSCmdlet, EnableException };
            PSCmdlet.InvokeCommand.InvokeScript(false, errorBlock, null, arguments);
        }
    }
}
