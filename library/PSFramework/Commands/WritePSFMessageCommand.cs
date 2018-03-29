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

        /// <summary>
        /// Non-colored version of developermode
        /// </summary>
        private string _messageDeveloper;

        /// <summary>
        /// Colored version of developermode
        /// </summary>
        private string _messageDeveloperColor;
        #endregion Private fields

        #region Private properties
        /// <summary>
        /// The input message with the error content included if desired
        /// </summary>
        private string _errorQualifiedMessage
        {
            get
            {
                if (ErrorRecord == null)
                    return Message;

                if (ErrorRecord.Length == 0)
                    return Message;

                if (OverrideExceptionMessage.ToBool())
                    return Message;

                if (Regex.IsMatch(Message, Regex.Escape(ErrorRecord[0].Exception.Message)))
                    return Message;

                return String.Format("{0} | {1}", Message, ErrorRecord[0].Exception.Message);
            }
        }

        /// <summary>
        /// The final message to use for internal logging
        /// </summary>
        private string _MessageSystem
        {
            get
            {
                return GetMessageSimple();
            }
        }

        /// <summary>
        /// The final message to use for writing to streams, such as verbose or warning
        /// </summary>
        private string _MessageStreams
        {
            get
            {
                if (MessageHost.DeveloperMode)
                    return GetMessageDeveloper();
                else
                    return GetMessage();
            }
        }

        /// <summary>
        /// The final message to use for host messages (write using Write-PSFHostColor)
        /// </summary>
        private string _MessageHost
        {
            get
            {
                if (MessageHost.DeveloperMode)
                    return GetMessageDeveloperColor();
                else
                    return GetMessageColor();
            }
        }
        #endregion Private properties

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

            #region Error handling
            if (ErrorRecord != null)
            {
                if (!_fromStopFunction)
                    if (EnableException)
                        foreach (ErrorRecord record in ErrorRecord)
                            WriteError(record);

                LogHost.WriteErrorEntry(ErrorRecord, FunctionName, ModuleName, new List<string>(Tag), _timestamp, _MessageSystem, System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId, Environment.MachineName);
            }
            #endregion Error handling

            List<string> channels = new List<string>();

            #region Warning handling
            if (Level == MessageLevel.Warning)
            {
                if (!_silent)
                {
                    if (!String.IsNullOrEmpty(Once))
                    {
                        string onceName = String.Format("MessageOnce.{0}.{1}", FunctionName, Once).ToLower();
                        if (!(Configuration.ConfigurationHost.Configurations.ContainsKey(onceName) && (bool)Configuration.ConfigurationHost.Configurations[onceName].Value))
                        {
                            WriteWarning(_MessageStreams);
                            channels.Add("Warning");

                            Configuration.Config cfg = new Configuration.Config();
                            cfg.Module = "messageonce";
                            cfg.Name = String.Format("{0}.{1}", FunctionName, Once).ToLower();
                            cfg.Hidden = true;
                            cfg.Description = "Locking setting that disables further display of the specified message";

                            Configuration.ConfigurationHost.Configurations[onceName] = cfg;
                        }
                    }
                    else
                    {
                        WriteWarning(_MessageStreams);
                        channels.Add("Warning");
                    }
                }
                WriteDebug(_MessageStreams);
                channels.Add("Debug");
            }
            #endregion Warning handling

            #region Message handling

            #endregion Message handling

            #region Logging

            #endregion Logging
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
        /// Builds the message item for display of Verbose, Warning and Debug streams
        /// </summary>
        /// <returns>The message to return</returns>
        private string GetMessage()
        {
            if (!String.IsNullOrEmpty(_message))
                return _message;
            _message = String.Format("[{0}][{1}] {2}", _timestamp.ToString("HH:mm:ss"), FunctionName, GetMessageSimple());
            return _message;
        }

        /// <summary>
        /// Builds the base message for internal system use.
        /// </summary>
        /// <returns>The message to return</returns>
        private string GetMessageSimple()
        {
            if (!String.IsNullOrEmpty(_messageSimple))
                return _messageSimple;

            string baseMessage = _errorQualifiedMessage;
            foreach (Match match in Regex.Matches(baseMessage, "<c=[\"'](.*?)[\"']>(.*?)</c>"))
                baseMessage = Regex.Replace(baseMessage, Regex.Escape(match.Value), "$2");
            _messageSimple = baseMessage;

            return _messageSimple;
        }

        /// <summary>
        /// Builds the message item if needed and returns it
        /// </summary>
        /// <returns>The message to return</returns>
        private string GetMessageColor()
        {
            if (!String.IsNullOrEmpty(_messageColor))
                return _messageColor;

            _messageColor = String.Format("[<c='sub'>{0}</c>][<c='sub'>{1}</c>] {2}", _timestamp.ToString("HH:mm:ss"), FunctionName, _errorQualifiedMessage);
            return _messageColor;
        }

        /// <summary>
        /// Non-host output in developermode
        /// </summary>
        /// <returns>The string to write on messages that don't go straight to Write-PSFHostColor</returns>
        private string GetMessageDeveloper()
        {
            if (!String.IsNullOrEmpty(_messageDeveloper))
                return _messageDeveloper;

            string targetString = "";
            if (Target != null)
            {
                if (Target.ToString() != Target.GetType().FullName)
                    targetString = String.Format(" [T: {0}] ", Target.ToString());
                else
                    targetString = String.Format(" [T: <{0}>] ", Target.GetType().Name);
            }

            List<string> channelList = new List<string>();
            if (!_silent)
            {
                if (Level == MessageLevel.Warning)
                    channelList.Add("Warning");
                if ((MessageHost.MaximumInformation >= (int)Level) && (MessageHost.MinimumInformation <= (int)Level))
                    channelList.Add("Information");
            }
            if ((MessageHost.MaximumVerbose >= (int)Level) && (MessageHost.MinimumVerbose <= (int)Level))
                channelList.Add("Verbose");
            if ((MessageHost.MaximumDebug >= (int)Level) && (MessageHost.MinimumDebug <= (int)Level))
                channelList.Add("Debug");

            _messageDeveloper = String.Format(@"[{0}][{1}][L: {2}]{3}[C: {4}][EE: {5}][O: {6}]
    {7}",_timestamp.ToString("HH:mm:ss"), FunctionName, Level, targetString, String.Join(",", channelList), EnableException, (!String.IsNullOrEmpty(Once)), GetMessageSimple());
            
            return _messageDeveloper;
        }

        /// <summary>
        /// Host output in developermode
        /// </summary>
        /// <returns>The string to write on messages that go straight to Write-PSFHostColor</returns>
        private string GetMessageDeveloperColor()
        {
            if (!String.IsNullOrEmpty(_messageDeveloperColor))
                return _messageDeveloperColor;

            string targetString = "";
            if (Target != null)
            {
                if (Target.ToString() != Target.GetType().FullName)
                    targetString = String.Format(" [<c='sub'>T:</c> <c='em'>{0}</c>] ", Target.ToString());
                else
                    targetString = String.Format(" [<c='sub'>T:</c> <c='em'><{0}></c>] ", Target.GetType().Name);
            }

            List<string> channelList = new List<string>();
            if (!_silent)
            {
                if (Level == MessageLevel.Warning)
                    channelList.Add("Warning");
                if ((MessageHost.MaximumInformation >= (int)Level) && (MessageHost.MinimumInformation <= (int)Level))
                    channelList.Add("Information");
            }
            if ((MessageHost.MaximumVerbose >= (int)Level) && (MessageHost.MinimumVerbose <= (int)Level))
                channelList.Add("Verbose");
            if ((MessageHost.MaximumDebug >= (int)Level) && (MessageHost.MinimumDebug <= (int)Level))
                channelList.Add("Debug");

            _messageDeveloperColor = String.Format(@"[<c='sub'>{0}</c>][<c='sub'>{1}</c>][<c='sub'>L:</c> <c='em'>{2}</c>]{3}[<c='sub'>C: <c='em'>{4}</c>][<c='sub'>EE: <c='em'>{5}</c>][<c='sub'>O: <c='em'>{6}</c>]
    {7}", _timestamp.ToString("HH:mm:ss"), FunctionName, Level, targetString, String.Join(",", channelList), EnableException, (!String.IsNullOrEmpty(Once)), _errorQualifiedMessage);

            return _messageDeveloperColor;
        }
        #endregion Helper methods
    }
}
