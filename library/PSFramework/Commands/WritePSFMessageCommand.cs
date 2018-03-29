using PSFramework.Message;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;

namespace PSFramework.Commands
{
    /// <summary>
    /// Cmdlet performing message handling and logging
    /// </summary>
    [Cmdlet("Write","PSFMessage")]
    public class WritePSFMessageCommand : PSCmdlet
    {
        #region Parameters
        [Parameter()]
        public MessageLevel Level = MessageLevel.Verbose;

        [Parameter(Mandatory = true, Position = 0)]
        public string Message;

        [Parameter()]
        public string[] Tag;

        [Parameter()]
        public string FunctionName;

        [Parameter()]
        public string ModuleName;

        [Parameter()]
        public string File;

        [Parameter()]
        public int Line;

        [Parameter()]
        public ErrorRecord[] ErrorRecord;

        [Parameter()]
        public Exception Exception;

        [Parameter()]
        public string Once;

        [Parameter()]
        public SwitchParameter OverrideExceptionMessage;

        [Parameter()]
        public object Target;

        [Parameter()]
        public bool EnableException;
        #endregion Parameters

        #region Private fields
        /// <summary>
        /// The start time of the cmdlet
        /// </summary>
        private DateTime _timestamp;

        /// <summary>
        /// Whether this cmdlet is run in silent mode
        /// </summary>
        private bool _silent = false;

        /// <summary>
        /// Whether this cmdlet was called by Stop-PSFFunction
        /// </summary>
        private bool _fromStopFunction = false;

        /// <summary>
        /// How many items exist on the callstack
        /// </summary>
        private int _stackDepth;

        /// <summary>
        /// The message to write
        /// </summary>
        private string _message;

        /// <summary>
        /// The message simplified without timestamps. Used for logging.
        /// </summary>
        private string _messageSimple;

        /// <summary>
        /// The message to write in color
        /// </summary>
        private string _messageColor;
        #endregion Private fields

        #region Cmdlet Implementation
        /// <summary>
        /// Processes the begin phase of the cmdlet
        /// </summary>
        protected override void BeginProcessing()
        {
            _timestamp = DateTime.Now;

            #region Resolving Meta Information
            CallStackFrame callerFrame = null;
            foreach (CallStackFrame frame in System.Management.Automation.Runspaces.Runspace.DefaultRunspace.Debugger.GetCallStack())
            {
                callerFrame = frame;
                break;
            }
            _stackDepth = System.Management.Automation.Runspaces.Runspace.DefaultRunspace.Debugger.GetCallStack().Count();

            if (callerFrame == null)
                WriteVerbose("No callstack found");
            else
                WriteVerbose(String.Format("Calling command: {0}", callerFrame.FunctionName));

            if (callerFrame != null)
            {
                if (String.IsNullOrEmpty(FunctionName))
                {
                    if (callerFrame.InvocationInfo == null)
                        FunctionName = callerFrame.FunctionName;
                    else if (callerFrame.InvocationInfo.MyCommand == null)
                        FunctionName = callerFrame.InvocationInfo.InvocationName;
                    else if (callerFrame.InvocationInfo.MyCommand.Name != "")
                        FunctionName = callerFrame.InvocationInfo.MyCommand.Name;
                    else
                        FunctionName = callerFrame.FunctionName;
                }

                if (String.IsNullOrEmpty(ModuleName))
                    if ((callerFrame.InvocationInfo != null) && (callerFrame.InvocationInfo.MyCommand != null))
                        ModuleName = callerFrame.InvocationInfo.MyCommand.ModuleName;

                if (String.IsNullOrEmpty(File))
                    File = callerFrame.Position.File;

                if (Line <= 0)
                    Line = callerFrame.Position.EndLineNumber;

                if (callerFrame.FunctionName == "Stop-PSFFunction")
                    _fromStopFunction = true;
            }

            if (String.IsNullOrEmpty(FunctionName))
                FunctionName = "<Unknown>";
            if (String.IsNullOrEmpty(ModuleName))
                ModuleName = "<Unknown>";

            if (MessageHost.DisableVerbosity)
                _silent = true;
            #endregion Resolving Meta Information

            WriteObject(String.Format("{0} - {1} : {2} - {3}", ModuleName, FunctionName, Line, File));
        }

        /// <summary>
        /// Processes the process phase of the cmdlet
        /// </summary>
        protected override void ProcessRecord()
        {
            #region Perform Transforms
            if ((!_fromStopFunction) && (Target != null))
                Target = ResolveTarget(Target);

            if (!_fromStopFunction)
            {
                if (Exception != null)
                    Exception = ResolveException(Exception);
                else if (ErrorRecord != null)
                {
                    Exception tempException = null;
                    for (int n = 0; n < ErrorRecord.Length; n++)
                    {
                        // If both Exception and ErrorRecord are specified, override the first error record's exception.
                        if ((n == 0) && (Exception != null))
                            tempException = Exception;
                        else
                            tempException = ResolveException(ErrorRecord[n].Exception);
                        if (tempException != ErrorRecord[n].Exception)
                            ErrorRecord[n] = new ErrorRecord(tempException, ErrorRecord[n].FullyQualifiedErrorId, ErrorRecord[n].CategoryInfo.Category, ErrorRecord[n].TargetObject);
                    }
                }
            }

            if (Level != MessageLevel.Warning)
                Level = ResolveLevel(Level);
            #endregion Perform Transforms

            #region Exception Integration
            /*
                While conclusive error handling must happen after message handling,
                in order to integrate the exception message into the actual message,
                it becomes necessary to first integrate the exception and error record parameters into a uniform view
	
                Note: Stop-PSFFunction never specifies this parameter, thus it is not necessary to check,
                whether this function was called from Stop-PSFFunction.
             */
            if (ErrorRecord == null)
            {
                ErrorRecord = new ErrorRecord[1];

                if (Exception != null)
                    ErrorRecord[0] = new ErrorRecord(Exception, String.Format("{0}_{1}", ModuleName, FunctionName), ErrorCategory.NotSpecified, Target);
                else
                    ErrorRecord[0] = new ErrorRecord(new Exception(Message), String.Format("{0}_{1}", ModuleName, FunctionName), ErrorCategory.NotSpecified, Target);
            }
            #endregion Exception Integration

            #region Handle Message Content
            string coloredMessage = Message;
            string baseMessage = Message;

            foreach (Match match in Regex.Matches(baseMessage, "<c=[\"'](.*?)[\"']>(.*?)</c>"))
                baseMessage = Regex.Replace(baseMessage, Regex.Escape(match.Value), "$2");


            #endregion Handle Message Content
        }

        /// <summary>
        /// Processes the end phase of the cmdlet
        /// </summary>
        protected override void EndProcessing()
        {
            base.EndProcessing();
        }
        #endregion Cmdlet Implementation

        #region Helper methods
        /// <summary>
        /// Processes the target transform rules on an input object
        /// </summary>
        /// <param name="Item">The item to transform</param>
        /// <returns>The transformed object</returns>
        private object ResolveTarget(object Item)
        {
            if (Item == null)
                return null;

            string lowTypeName = Item.GetType().FullName.ToLower();

            if (MessageHost.TargetTransforms.ContainsKey(lowTypeName))
            {
                try { return InvokeCommand.InvokeScript(false, ScriptBlock.Create(MessageHost.TargetTransforms[lowTypeName].ToString()), null, null); }
                catch (Exception e)
                {
                    MessageHost.WriteTransformError(new ErrorRecord(e, "Write-PSFMessage", ErrorCategory.OperationStopped, null), FunctionName, ModuleName, Item, TransformType.Target, System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId);
                    return Item;
                }
            }

            TransformCondition transform = MessageHost.TargetTransformlist.Get(lowTypeName, ModuleName, FunctionName);
            if (transform != null)
            {
                try { return InvokeCommand.InvokeScript(false, ScriptBlock.Create(transform.ScriptBlock.ToString()), null, null); }
                catch (Exception e)
                {
                    MessageHost.WriteTransformError(new ErrorRecord(e, "Write-PSFMessage", ErrorCategory.OperationStopped, null), FunctionName, ModuleName, Item, TransformType.Target, System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId);
                    return Item;
                }
            }

            return Item;
        }

        /// <summary>
        /// Processes the specified exception specified
        /// </summary>
        /// <param name="Item">The exception to process</param>
        /// <returns>The transformed exception</returns>
        private Exception ResolveException(Exception Item)
        {
            if (Item == null)
                return Item;

            string lowTypeName = Item.GetType().FullName.ToLower();

            if (MessageHost.ExceptionTransforms.ContainsKey(lowTypeName))
            {
                try { return (Exception)InvokeCommand.InvokeScript(false, ScriptBlock.Create(MessageHost.ExceptionTransforms[lowTypeName].ToString()), null, null)[0].BaseObject; }
                catch (Exception e)
                {
                    MessageHost.WriteTransformError(new ErrorRecord(e, "Write-PSFMessage", ErrorCategory.OperationStopped, null), FunctionName, ModuleName, Item, TransformType.Exception, System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId);
                    return Item;
                }
            }

            TransformCondition transform = MessageHost.ExceptionTransformList.Get(lowTypeName, ModuleName, FunctionName);
            if (transform != null)
            {
                try { return (Exception)InvokeCommand.InvokeScript(false, ScriptBlock.Create(transform.ScriptBlock.ToString()), null, null)[0].BaseObject; }
                catch (Exception e)
                {
                    MessageHost.WriteTransformError(new ErrorRecord(e, "Write-PSFMessage", ErrorCategory.OperationStopped, null), FunctionName, ModuleName, Item, TransformType.Exception, System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId);
                    return Item;
                }
            }

            return Item;
        }

        /// <summary>
        /// Processs the input level and apply policy and rules
        /// </summary>
        /// <param name="Level">The original level of the message</param>
        /// <returns>The processed level</returns>
        private MessageLevel ResolveLevel(MessageLevel Level)
        {
            int tempLevel = (int)Level;

            if (MessageHost.NestedLevelDecrement > 0)
            {
                int depth = _stackDepth - 2;
                if (_fromStopFunction)
                    depth--;
                tempLevel = tempLevel + depth * MessageHost.NestedLevelDecrement;
            }

            List<string>  tags = new List<string>(Tag);
            foreach (MessageLevelModifier modifier in MessageHost.MessageLevelModifiers.Values)
                if (modifier.AppliesTo(FunctionName, ModuleName, tags))
                    tempLevel = tempLevel + modifier.Modifier;

            if (tempLevel > 9)
                tempLevel = 9;
            if (tempLevel < 1)
                tempLevel = 1;

            return (MessageLevel)tempLevel;
        }

        /// <summary>
        /// Builds the message item if needed and returns it
        /// </summary>
        /// <returns>The message to return</returns>
        public string GetMessage()
        {
            if (!String.IsNullOrEmpty(_message))
                return _message;
            return _message;
        }

        /// <summary>
        /// Builds the message item if needed and returns it
        /// </summary>
        /// <returns>The message to return</returns>
        public string GetMessageSimple()
        {
            if (!String.IsNullOrEmpty(_messageSimple))
                return _messageSimple;
            return _messageSimple;
        }

        /// <summary>
        /// Builds the message item if needed and returns it
        /// </summary>
        /// <returns>The message to return</returns>
        public string GetMessageColor()
        {
            if (!String.IsNullOrEmpty(_messageColor))
                return _messageColor;
            return _messageColor;
        }
        #endregion Helper methods
    }
}
