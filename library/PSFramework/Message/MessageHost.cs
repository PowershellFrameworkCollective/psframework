using System;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Management.Automation;

namespace PSFramework.Message
{
    /// <summary>
    /// Provides static resources to the messaging subsystem
    /// </summary>
    public static class MessageHost
    {
        #region Defines
        /// <summary>
        /// The maximum message level to still display to the user directly.
        /// </summary>
        public static int MaximumInformation = 3;

        /// <summary>
        /// The maxium message level where verbose information is still written.
        /// </summary>
        public static int MaximumVerbose = 6;

        /// <summary>
        /// The maximum message level where debug information is still written.
        /// </summary>
        public static int MaximumDebug = 9;

        /// <summary>
        /// The minimum required message level for messages that will be shown to the user.
        /// </summary>
        public static int MinimumInformation = 1;

        /// <summary>
        /// The minimum required message level where verbose information is written.
        /// </summary>
        public static int MinimumVerbose = 4;

        /// <summary>
        /// The minimum required message level where debug information is written.
        /// </summary>
        public static int MinimumDebug = 1;

        /// <summary>
        /// The color stuff gets written to the console in
        /// </summary>
        public static ConsoleColor InfoColor = ConsoleColor.Cyan;

        /// <summary>
        /// The color important stuff gets written to the console in
        /// </summary>
        public static ConsoleColor InfoColorEmphasis = ConsoleColor.Green;

        /// <summary>
        /// The color background stuff gets written to the console in
        /// </summary>
        public static ConsoleColor InfoColorSubtle = ConsoleColor.Gray;

        /// <summary>
        /// The color stuff gets written to the console in, when developer mode is enabled and the message would not have been written after all
        /// </summary>
        public static ConsoleColor DeveloperColor = ConsoleColor.Gray;

        /// <summary>
        /// Enables the developer mode. In this all messages are written to the console, in order to make it easier to troubleshoot issues.
        /// </summary>
        public static bool DeveloperMode = false;

        /// <summary>
        /// Message levels can decrease by nested level. This causes messages to have an increasingly reduced level as the size of the callstack increases. 
        /// </summary>
        public static int NestedLevelDecrement = 0;

        /// <summary>
        /// Globally override all verbosity
        /// </summary>
        public static bool DisableVerbosity = false;

        /// <summary>
        /// Include message timestamps in verbose message output
        /// </summary>
        public static bool EnableMessageTimestamp = true;

        /// <summary>
        /// Include message prefix in verbose message output
        /// </summary>
        public static bool EnableMessagePrefix = false;

        /// <summary>
        /// Include the message display command in the verbose message output
        /// </summary>
        public static bool EnableMessageDisplayCommand = true;

        /// <summary>
        /// Include the entire callstack in the verbose message output
        /// </summary>
        public static bool EnableMessageBreadcrumbs = false;

        /// <summary>
        /// Define the message prefix value for the critical level
        /// </summary>
        public static string PrefixValueCritical = "##vso[task.logissue type=error;]";

        /// <summary>
        /// Define the message prefix value for the warning level
        /// </summary>
        public static string PrefixValueWarning = "##vso[task.logissue type=warning;]";

        /// <summary>
        /// Define the message prefix value for the verbose level
        /// </summary>
        public static string PrefixValueVerbose = "##[debug]";

        /// <summary>
        /// Define the message prefix value for the host level
        /// </summary>
        public static string PrefixValueHost = "";

        /// <summary>
        /// Define the message prefix value for the important level
        /// </summary>
        public static string PrefixValueSignificant = "##[section]";
            

        #endregion Defines

        #region Transformations
        /// <summary>
        /// The size of the transform error queue. When adding more than this, the oldest entry will be discarded
        /// </summary>
        public static int TransformErrorQueueSize = 512;

        /// <summary>
        /// Provides the option to transform exceptions based on the original exception type
        /// </summary>
        public static ConcurrentDictionary<string, ScriptBlock> ExceptionTransforms = new ConcurrentDictionary<string, ScriptBlock>();

        /// <summary>
        /// Provides the option to transform target objects based on type. This is sometimes important when working with live state objects that should not be serialized.
        /// </summary>
        public static ConcurrentDictionary<string, ScriptBlock> TargetTransforms = new ConcurrentDictionary<string, ScriptBlock>();

        /// <summary>
        /// The list of transformation errors that occured.
        /// </summary>
        private static ConcurrentQueue<TransformError> TransformErrors = new ConcurrentQueue<TransformError>();

        /// <summary>
        /// Returns the current queue of failed transformations
        /// </summary>
        /// <returns>The list of transformations that failed</returns>
        public static TransformError[] GetTransformErrors()
        {
            return TransformErrors.ToArray();
        }

        /// <summary>
        /// Writes a new transform error
        /// </summary>
        /// <param name="Record">The record of what went wrong</param>
        /// <param name="FunctionName">The name of the function writing the transformed message</param>
        /// <param name="ModuleName">The module the function writing the transformed message is part of</param>
        /// <param name="Object">The object that should have been transformed</param>
        /// <param name="Type">The type of transform that was attempted</param>
        /// <param name="Runspace">The runspace it all happened on</param>
        public static void WriteTransformError(ErrorRecord Record, string FunctionName, string ModuleName, object Object, TransformType Type, Guid Runspace)
        {
            TransformError tempError;

            TransformErrors.Enqueue(new TransformError(Record, FunctionName, ModuleName, Object, Type, Runspace));
            while (TransformErrors.Count > TransformErrorQueueSize)
                TransformErrors.TryDequeue(out tempError);
        }

        /// <summary>
        /// List of custom transforms for exceptions
        /// </summary>
        public static TransformList ExceptionTransformList = new TransformList();

        /// <summary>
        /// List of custom transforms for targets
        /// </summary>
        public static TransformList TargetTransformlist = new TransformList();

        /// <summary>
        /// List of all modifiers that apply to message levels
        /// </summary>
        public static ConcurrentDictionary<string, MessageLevelModifier> MessageLevelModifiers = new ConcurrentDictionary<string, MessageLevelModifier>();
        #endregion Transformations

        #region Events
        /// <summary>
        /// List of events that subscribe to messages being written
        /// </summary>
        public static ConcurrentDictionary<string, MessageEventSubscription> Events = new ConcurrentDictionary<string, MessageEventSubscription>();
        #endregion Events
    }
}
