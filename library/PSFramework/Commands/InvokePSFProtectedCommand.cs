using PSFramework.Parameter;
using PSFramework.Utility;
using System;
using System.Collections;
using System.Diagnostics;
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
        /// The multiplier applied to waits over the previous wait.
        /// </summary>
        [Parameter()]
        public double RetryWaitEscalation = 1;

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

        /// <summary>
        /// Code to execute if giving up in failure
        /// </summary>
        [Parameter()]
        public ScriptBlock ErrorEvent;

        /// <summary>
        /// The message level at which to generate non-error messages written by this cmdlet
        /// </summary>
        [Parameter()]
        public Message.MessageLevel Level = Message.MessageLevel.SomewhatVerbose;

        /// <summary>
        /// Make the final error generated a nonterminating error
        /// </summary>
        [Parameter()]
        public SwitchParameter NonTerminating;
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
            bool test;
            if (MyInvocation.BoundParameters.ContainsKey("WhatIf") || MyInvocation.BoundParameters.ContainsKey("Confirm"))
                test = ShouldProcess(LanguagePrimitives.ConvertTo<string>(Target), _Message);
            else
                test = PSCmdlet.ShouldProcess(LanguagePrimitives.ConvertTo<string>(Target), _Message);

            if (test)
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Confirmed", new object[] { _Message }), Level, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
            else
            {
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Denied", new object[] { _Message }), Level, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
                return;
            }

            int countAttempted = 0;
            int nextWait = (int)RetryWait.Value.TotalMilliseconds;
            while (countAttempted <= RetryCount)
            {
                countAttempted++;

                try
                {
                    var result = PSCmdlet.InvokeCommand.InvokeScript(false, ScriptBlock, null, null);
                    WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Success", new object[] { _Message }), Level, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
                    if (result != null && result.Count > 0)
                        WriteObject(result, true);
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
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.Retry", new object[] { countAttempted, (RetryCount + 1), _Message }), Level, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
                Thread.Sleep(nextWait);
                nextWait = (int)((double)nextWait * RetryWaitEscalation);
            }
            
        }
        #endregion Cmdlet Implementation

        private void Terminate(Exception error)
        {
            ErrorEventAction(error);
            if (NonTerminating.ToBool())
            {
                WriteMessage(_ErrorMessage, Message.MessageLevel.Error, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target, null, error);
                if (EnableException)
                {
                    if (error as RuntimeException != null)
                        PSCmdlet.WriteError(((RuntimeException)error).ErrorRecord);
                    else
                        PSCmdlet.WriteError(
                            new ErrorRecord(
                                error,
                                "ItFailed",
                                ErrorCategory.NotSpecified,
                                Target
                            )
                        );
                }
                    
                if (Continue)
                    DoContinue(ContinueLabel);
                return;
            }

            using (PowerShell ps = PowerShell.Create(RunspaceMode.CurrentRunspace))
            {
                ps.AddCommand("PSFramework\\Stop-PSFFunction")
                    .AddParameter("Message", _ErrorMessage)
                    .AddParameter("Exception", error)
                    .AddParameter("Target", Target)
                    .AddParameter("Continue", Continue)
                    .AddParameter("FunctionName", _Caller.CallerFunction)
                    .AddParameter("ModuleName", _Caller.CallerModule)
                    .AddParameter("File", _Caller.CallerFile)
                    .AddParameter("Line", _Caller.CallerLine)
                    .AddParameter("Cmdlet", PSCmdlet)
                    .AddParameter("EnableException", EnableException);
                if (!String.IsNullOrEmpty(ContinueLabel))
                    ps.AddParameter("ContinueLabel", ContinueLabel);

                ps.Invoke();
            }
        }

        private void ErrorEventAction(Exception error)
        {
            if (ErrorEvent == null)
                return;
            Hashtable table = new Hashtable();
            object errorRecord = error;
            if (error is RuntimeException)
                errorRecord = ((RuntimeException)error).ErrorRecord;
            try {
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.ErrorEvent", new object[] { _Message, Target }), Level, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target);
                table["Result"] = PSCmdlet.InvokeCommand.InvokeScript(false, ErrorEvent, null, errorRecord);
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.ErrorEvent.Success", new object[] { _Message, Target }), Level, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target, table);
            }
            catch (Exception e)
            {
                table["Error"] = e;
                WriteMessage(Localization.LocalizationHost.Read("PSFramework.FlowControl.Invoke-PSFProtectedCommand.ErrorEvent.Failed", new object[] { _Message, Target, e.Message }), Message.MessageLevel.Warning, _Caller.CallerFunction, _Caller.CallerModule, _Caller.CallerFile, _Caller.CallerLine, Tag, Target, table);
            }
        }
    }
}
