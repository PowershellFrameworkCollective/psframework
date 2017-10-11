﻿using System;
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
        #endregion Defines

        #region Transformations
        /// <summary>
        /// The size of the transform error queue. When adding more than this, the oldest entry will be discarded
        /// </summary>
        public static int TransformErrorQueueSize = 512;

        /// <summary>
        /// Provides the option to transform exceptions based on the original exception type
        /// </summary>
        public static Dictionary<string, ScriptBlock> ExceptionTransforms = new Dictionary<string, ScriptBlock>();

        /// <summary>
        /// Provides the option to transform target objects based on type. This is sometimes important when working with live state objects that should not be serialized.
        /// </summary>
        public static Dictionary<string, ScriptBlock> TargetTransforms = new Dictionary<string, ScriptBlock>();

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
        #endregion Transformations

        #region Events
        /// <summary>
        /// List of events that subscribe to messages being written
        /// </summary>
        public static Dictionary<string, MessageEventSubscription> Events = new Dictionary<string, MessageEventSubscription>();
        #endregion Events
    }
}
