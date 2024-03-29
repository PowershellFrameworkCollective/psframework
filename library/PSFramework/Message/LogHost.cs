﻿using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Management.Automation;

namespace PSFramework.Message
{
    /// <summary>
    /// Provides static information storage for logging related settings, as well as housing the logging queues.
    /// </summary>
    public static class LogHost
    {
        #region Defines
        /// <summary>
        /// The maximum numbers of error records maintained in-memory.
        /// </summary>
        public static int MaxErrorCount = 128;

        /// <summary>
        /// The maximum number of messages that can be maintained in the in-memory message queue
        /// </summary>
        public static int MaxMessageCount = 1024;

        /// <summary>
        /// The maximum size of a given logfile. When reaching this limit, the file will be abandoned and a new log created. Set to 0 to not limit the size.
        /// </summary>
        public static int MaxMessagefileBytes = 5242880; // 5MB

        /// <summary>
        /// The maximum number of logfiles maintained at a time. Exceeding this number will cause the oldest to be culled. Set to 0 to disable the limit.
        /// </summary>
        public static int MaxMessagefileCount = 5;

        /// <summary>
        /// The maximum size all error files combined may have. When this number is exceeded, the oldest entry is culled.
        /// </summary>
        public static int MaxErrorFileBytes = 20971520; // 20MB

        /// <summary>
        /// This is the upper limit of length all items in the log folder may have combined across all processes.
        /// </summary>
        public static int MaxTotalFolderSize = 104857600; // 100MB

        /// <summary>
        /// Path to where the logfiles live.
        /// </summary>
        public static string LoggingPath;

        /// <summary>
        /// Any logfile older than this will automatically be cleansed
        /// </summary>
        public static TimeSpan MaxLogFileAge = new TimeSpan(7, 0, 0, 0);

        /// <summary>
        /// Governs, whether a log file for the system messages is written
        /// </summary>
        public static bool MessageLogFileEnabled = true;

        /// <summary>
        /// Governs, whether a log of recent messages is kept in memory
        /// </summary>
        public static bool MessageLogEnabled = true;

        /// <summary>
        /// Governs, whether log files for errors are written
        /// </summary>
        public static bool ErrorLogFileEnabled = true;

        /// <summary>
        /// Governs, whether a log of recent errors is kept in memory
        /// </summary>
        public static bool ErrorLogEnabled = true;

        /// <summary>
        /// Whether the filesystem logging provider uses the modern logging style with CSV headers and extra columns
        /// </summary>
        public static bool FileSystemModernLog = false;

        /// <summary>
        /// The depth to which the target object should serialized.
        /// </summary>
        public static int FileSystemSerializationDepth = -1;

        /// <summary>
        /// The time pattern used when writing logfiles using the filesystem provider
        /// </summary>
        public static string TimeFormat = String.Format("{0} {1}", System.Globalization.CultureInfo.CurrentUICulture.DateTimeFormat.ShortDatePattern, System.Globalization.CultureInfo.CurrentUICulture.DateTimeFormat.LongTimePattern);

        /// <summary>
        /// The interval at which the loging runspace runs. Increase to improve performance, reduce the minimize writing latency.
        /// </summary>
        public static int Interval = 1000;

        /// <summary>
        /// The interval at which the loging runspace runs, when there is nothing to do.
        /// </summary>
        public static int IntervalIdle = 5000;

        /// <summary>
        /// The time with no message written that needs to occur for the logging runspace to switch to idle mode.
        /// </summary>
        public static TimeSpan IntervalIdleDuration = new TimeSpan(0, 2, 0);

        /// <summary>
        /// The time the last message or error were written.
        /// </summary>
        public static DateTime LastLogged = DateTime.Now;

        /// <summary>
        /// Whether the logging is enabled at all.
        /// Setting this to false will stop and prevent the start of the logging runspace.
        /// </summary>
        public static bool LoggingEnabled = true;

        /// <summary>
        /// The next interval to use.
        /// </summary>
        public static int NextInterval
        {
            get
            {
                if ((LastLogged.Add(IntervalIdleDuration)) > DateTime.Now)
                    return Interval;
                return IntervalIdle;
            }
        }
        #endregion Defines

        #region Queues
        private static ConcurrentQueue<PsfExceptionRecord> ErrorRecords = new ConcurrentQueue<PsfExceptionRecord>();

        private static ConcurrentQueue<LogEntry> LogEntries = new ConcurrentQueue<LogEntry>();

        /// <summary>
        /// The outbound queue for errors. These will be processed and written to xml
        /// </summary>
        public static ConcurrentQueue<PsfExceptionRecord> OutQueueError = new ConcurrentQueue<PsfExceptionRecord>();

        /// <summary>
        /// The outbound queue for logs. These will be processed and written to logfile
        /// </summary>
        public static ConcurrentQueue<LogEntry> OutQueueLog = new ConcurrentQueue<LogEntry>();
        #endregion Queues

        #region Access Queues
        /// <summary>
        /// Retrieves a copy of the Error stack
        /// </summary>
        /// <returns>All errors thrown by functions using the message or flowcontrol system</returns>
        public static PsfExceptionRecord[] GetErrors()
        {
            PsfExceptionRecord[] temp = new PsfExceptionRecord[ErrorRecords.Count];
            ErrorRecords.CopyTo(temp, 0);
            return temp;
        }

        /// <summary>
        /// Retrieves a copy of the message log
        /// </summary>
        /// <returns>All messages logged this session.</returns>
        public static LogEntry[] GetLog()
        {
            LogEntry[] temp = new LogEntry[LogEntries.Count];
            LogEntries.CopyTo(temp, 0);
            return temp;
        }

        /// <summary>
        /// Clears the current in-memory log
        /// </summary>
        public static void ClearLog()
        {
            LogEntries = new ConcurrentQueue<LogEntry>();
            ErrorRecords = new ConcurrentQueue<PsfExceptionRecord>();
        }

        /// <summary>
        /// Write an error record to the log
        /// </summary>
        /// <param name="Record">The actual error record as powershell wrote it</param>
        /// <param name="FunctionName">The name of the function writing the error</param>
        /// <param name="ModuleName">The name of the module the function writing the error came from</param>
        /// <param name="Tags">The tags that were assigned to the error event</param>
        /// <param name="Timestamp">When was the error written</param>
        /// <param name="Message">What message was passed to the user</param>
        /// <param name="Runspace">The runspace the message was written from</param>
        /// <param name="ComputerName">The computer the error was written on</param>
        /// <returns>The error entry, so it may be included in the message generated</returns>
        public static PsfExceptionRecord WriteErrorEntry(ErrorRecord[] Record, string FunctionName, string ModuleName, List<string> Tags, DateTime Timestamp, string Message, Guid Runspace, string ComputerName)
        {
            PsfExceptionRecord tempRecord = new PsfExceptionRecord(Runspace, ComputerName, Timestamp, FunctionName, ModuleName, Tags, Message);
            foreach (ErrorRecord rec in Record)
            {
                tempRecord.Exceptions.Add(new PsfException(rec, FunctionName, Timestamp, Message, Runspace, ComputerName));
            }

            if (ErrorLogFileEnabled) { OutQueueError.Enqueue(tempRecord); }
            if (ErrorLogEnabled) { ErrorRecords.Enqueue(tempRecord); }

            PsfExceptionRecord tmp;
            while ((MaxErrorCount > 0) && (ErrorRecords.Count > MaxErrorCount))
            {
                ErrorRecords.TryDequeue(out tmp);
            }
            return tempRecord;
        }

        /// <summary>
        /// Write a new entry to the log
        /// </summary>
        /// <param name="Message">The message to log</param>
        /// <param name="Type">The type of the message logged</param>
        /// <param name="Timestamp">When was the message generated</param>
        /// <param name="FunctionName">What function wrote the message</param>
        /// <param name="ModuleName">What module did the function writing this message come from?</param>
        /// <param name="Tags">The tags that were applied to the message</param>
        /// <param name="Data">Additional data provided by the message</param>
        /// <param name="Level">At what level was the function written</param>
        /// <param name="Runspace">The runspace the message is coming from</param>
        /// <param name="ComputerName">The computer the message was generated on</param>
        /// <param name="File">The file from which the message was written</param>
        /// <param name="Line">The line on which the message was written</param>
        /// <param name="TargetObject">The object associated with a given message.</param>
        /// <param name="CallStack">The callstack at the moment the message was written.</param>
        /// <param name="Username">The name of the user under which the code being executed</param>
        /// <param name="ErrorRecord">An associated error record</param>
        /// <returns>The entry that is being written</returns>
        public static LogEntry WriteLogEntry(string Message, LogEntryType Type, DateTime Timestamp, string FunctionName, string ModuleName, List<string> Tags, Hashtable Data, MessageLevel Level, Guid Runspace, string ComputerName, string File, int Line, IEnumerable<CallStackFrame> CallStack, string Username, PsfExceptionRecord ErrorRecord, object TargetObject = null)
        {
            return WriteLogEntry(Message, Type, Timestamp, FunctionName, ModuleName, Tags, Data, Level, Runspace, ComputerName, File, Line, CallStack, Username, ErrorRecord, "", null, TargetObject);
        }

        /// <summary>
        /// Write a new entry to the log
        /// </summary>
        /// <param name="Message">The message to log</param>
        /// <param name="Type">The type of the message logged</param>
        /// <param name="Timestamp">When was the message generated</param>
        /// <param name="FunctionName">What function wrote the message</param>
        /// <param name="ModuleName">What module did the function writing this message come from?</param>
        /// <param name="Tags">The tags that were applied to the message</param>
        /// <param name="Data">Additional data provided by the message</param>
        /// <param name="Level">At what level was the function written</param>
        /// <param name="Runspace">The runspace the message is coming from</param>
        /// <param name="ComputerName">The computer the message was generated on</param>
        /// <param name="File">The file from which the message was written</param>
        /// <param name="Line">The line on which the message was written</param>
        /// <param name="TargetObject">The object associated with a given message.</param>
        /// <param name="CallStack">The callstack at the moment the message was written.</param>
        /// <param name="Username">The name of the user under which the code being executed</param>
        /// <param name="String">The string key to use for retrieving localized strings</param>
        /// <param name="StringValue">The values to format into the localized string</param>
        /// <param name="ErrorRecord">An associated error record</param>
        /// <returns>The entry that is being written</returns>
        public static LogEntry WriteLogEntry(string Message, LogEntryType Type, DateTime Timestamp, string FunctionName, string ModuleName, List<string> Tags, Hashtable Data, MessageLevel Level, Guid Runspace, string ComputerName, string File, int Line, IEnumerable<CallStackFrame> CallStack, string Username, PsfExceptionRecord ErrorRecord, string String, object[] StringValue, object TargetObject = null)
        {
            LogEntry temp = new LogEntry(Message, Type, Timestamp, FunctionName, ModuleName, Tags, Data, Level, Runspace, ComputerName, TargetObject, File, Line, new PSFramework.Message.CallStack(CallStack), Username, ErrorRecord, String, StringValue);
            if (MessageLogFileEnabled) { OutQueueLog.Enqueue(temp); }
            if (MessageLogEnabled) { LogEntries.Enqueue(temp); }

            LogEntry tmp;
            while ((MaxMessageCount > 0) && (LogEntries.Count > MaxMessageCount))
            {
                LogEntries.TryDequeue(out tmp);
            }

            return temp;
        }
        #endregion Access Queues
    }
}
